import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { errorResponse, jsonResponse } from "../_shared/http.ts";
import { hasBillingAdminRole } from "../_shared/mercadopago/auth.ts";
import { MercadoPagoClient } from "../_shared/mercadopago/client.ts";
import { getMercadoPagoEnv } from "../_shared/mercadopago/env.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return errorResponse("Method not allowed", 405);
  const authHeader = request.headers.get("Authorization");
  if (!authHeader) return errorResponse("Não autenticado.", 401);
  let body: { planId?: string; newPrice?: number };
  try {
    body = await request.json();
  } catch (_) {
    return errorResponse("Payload inválido.", 400);
  }
  const price = Number(body.newPrice);
  const newAmountCents = Math.round(price * 100);
  if (!body.planId || !Number.isFinite(price) || newAmountCents <= 0) {
    return errorResponse("planId e newPrice válido são obrigatórios.", 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const serviceClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: auth, error: authError } = await userClient.auth.getUser();
  if (authError || !auth.user) return errorResponse("Não autenticado.", 401);
  if (!await hasBillingAdminRole(userClient, auth.user.id)) {
    return errorResponse("Sem permissão para reajustar o plano.", 403);
  }

  const { data: plan, error: planError } = await serviceClient.from("plans")
    .select("id,price,subscription_type,mercadopago_preapproval_plan_id")
    .eq("id", body.planId).maybeSingle();
  if (planError || !plan) return errorResponse("Plano não encontrado.", 404);
  if (plan.subscription_type !== "mensal" || !plan.mercadopago_preapproval_plan_id) {
    return errorResponse("Plano mensal não publicado no Mercado Pago.", 409);
  }

  const oldAmountCents = Math.round(Number(plan.price) * 100);
  if (oldAmountCents === newAmountCents) {
    return jsonResponse({ planId: plan.id, status: "completed", changed: false });
  }
  const { data: openJob } = await serviceClient.from("mercadopago_price_change_jobs")
    .select("id,status,new_amount_cents")
    .eq("plan_id", plan.id)
    .in("status", ["pending", "processing"])
    .maybeSingle();
  if (openJob) {
    return jsonResponse({ jobId: openJob.id, status: openJob.status, changed: false }, 202);
  }

  const { data: job, error: jobError } = await serviceClient
    .from("mercadopago_price_change_jobs")
    .insert({
      plan_id: plan.id,
      old_amount_cents: oldAmountCents,
      new_amount_cents: newAmountCents,
      status: "pending",
      requested_by: auth.user.id,
    }).select("id").single();
  if (jobError || !job) return errorResponse("Não foi possível iniciar o reajuste.", 409);

  try {
    const mercadoPago = new MercadoPagoClient(getMercadoPagoEnv());
    await mercadoPago.updatePlan(plan.mercadopago_preapproval_plan_id, {
      auto_recurring: { transaction_amount: newAmountCents / 100, currency_id: "BRL" },
    });
    const now = new Date().toISOString();
    await serviceClient.from("plans").update({
      price: newAmountCents / 100,
      updated_at: now,
    }).eq("id", plan.id);
    await serviceClient.from("mercadopago_price_change_jobs").update({
      status: "processing",
      provider_plan_updated_at: now,
      started_at: now,
      updated_at: now,
    }).eq("id", job.id);

    const { data: subscriptions } = await serviceClient.from("subscriptions")
      .select("id,mercadopago_preapproval_id")
      .eq("plan_id", plan.id)
      .eq("payment_provider", "mercado_pago")
      .in("status", ["active", "payment_pending", "waiting_authorization"])
      .not("mercadopago_preapproval_id", "is", null);
    if (subscriptions?.length) {
      await serviceClient.from("mercadopago_price_change_items").insert(
        subscriptions.map((subscription: any) => ({
          job_id: job.id,
          subscription_id: subscription.id,
          preapproval_id: subscription.mercadopago_preapproval_id,
        })),
      );
    } else {
      await serviceClient.from("mercadopago_price_change_jobs").update({
        status: "completed",
        completed_at: now,
        updated_at: now,
      }).eq("id", job.id);
    }
    return jsonResponse({ jobId: job.id, status: subscriptions?.length ? "processing" : "completed" }, 202);
  } catch (_) {
    await serviceClient.from("mercadopago_price_change_jobs").update({
      status: "failed",
      last_error: "Falha ao atualizar o plano no provedor.",
      completed_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }).eq("id", job.id);
    return errorResponse("Não foi possível atualizar o plano no Mercado Pago.", 502);
  }
});

