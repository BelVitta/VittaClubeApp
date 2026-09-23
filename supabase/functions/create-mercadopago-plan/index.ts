import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { errorResponse, jsonResponse } from "../_shared/http.ts";
import { hasBillingAdminRole } from "../_shared/mercadopago/auth.ts";
import { MercadoPagoClient } from "../_shared/mercadopago/client.ts";
import { getMercadoPagoEnv } from "../_shared/mercadopago/env.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return errorResponse("Method not allowed", 405);
  const authHeader = request.headers.get("Authorization");
  if (!authHeader) return errorResponse("Não autenticado.", 401);

  let body: { planId?: string };
  try {
    body = await request.json();
  } catch (_) {
    return errorResponse("Payload inválido.", 400);
  }
  if (!body.planId) return errorResponse("planId é obrigatório.", 400);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const serviceClient = createClient(
    supabaseUrl,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: auth, error: authError } = await userClient.auth.getUser();
  if (authError || !auth.user) return errorResponse("Não autenticado.", 401);
  if (!await hasBillingAdminRole(userClient, auth.user.id)) {
    return errorResponse("Sem permissão para criar o plano de cobrança.", 403);
  }

  const { data: plan, error: planError } = await serviceClient
    .from("plans")
    .select("id,name,subscription_type,price,is_active,mercadopago_preapproval_plan_id")
    .eq("id", body.planId)
    .maybeSingle();
  if (planError || !plan) return errorResponse("Plano não encontrado.", 404);
  if (plan.subscription_type !== "mensal" || !plan.is_active) {
    return errorResponse("Somente o plano mensal ativo pode ser publicado.", 409);
  }
  if (plan.mercadopago_preapproval_plan_id) {
    return jsonResponse({
      planId: plan.id,
      providerPlanId: plan.mercadopago_preapproval_plan_id,
      created: false,
    });
  }

  try {
    const mercadoPago = new MercadoPagoClient(getMercadoPagoEnv());
    const remote = await mercadoPago.createPlan({
      reason: "VittaClube - assinatura mensal contínua",
      external_reference: plan.id,
      back_url: getMercadoPagoEnv().returnUrl,
      auto_recurring: {
        frequency: 1,
        frequency_type: "months",
        transaction_amount: Number(plan.price),
        currency_id: "BRL",
      },
    }, `vittaclube-plan-${plan.id}`);
    const providerPlanId = String(remote.id ?? "");
    if (!providerPlanId) throw new Error("Plano criado sem identificador.");

    const { error: updateError } = await serviceClient
      .from("plans")
      .update({ mercadopago_preapproval_plan_id: providerPlanId })
      .eq("id", plan.id)
      .is("mercadopago_preapproval_plan_id", null);
    if (updateError) throw updateError;

    return jsonResponse({ planId: plan.id, providerPlanId, created: true }, 201);
  } catch (_) {
    return errorResponse("Não foi possível criar o plano no Mercado Pago.", 502);
  }
});

