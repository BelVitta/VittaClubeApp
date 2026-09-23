import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { enforceRateLimit, errorResponse, jsonResponse } from "../_shared/http.ts";
import {
  MercadoPagoApiError,
  MercadoPagoClient,
} from "../_shared/mercadopago/client.ts";
import { getMercadoPagoEnv } from "../_shared/mercadopago/env.ts";

interface CreateBody {
  planId?: string;
  cardTokenId?: string;
  [key: string]: unknown;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return errorResponse("Method not allowed", 405);
  const authHeader = request.headers.get("Authorization");
  if (!authHeader) return errorResponse("Não autenticado.", 401);

  let body: CreateBody;
  try {
    body = await request.json();
  } catch (_) {
    return errorResponse("Payload inválido.", 400);
  }
  const unexpected = Object.keys(body).filter((key) =>
    !["planId", "cardTokenId"].includes(key)
  );
  if (unexpected.length > 0 || !body.planId || !body.cardTokenId) {
    return errorResponse("Envie somente planId e cardTokenId.", 400);
  }

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
  const limited = await enforceRateLimit(userClient, "create_mercadopago_subscription", 5);
  if (limited) return limited;

  const userId = auth.user.id;
  // Do not rely only on is_current here. A previous reconciliation may have
  // removed a pending row from that slot before the provider response arrived;
  // reusing that row is what prevents a second external preapproval.
  const { data: existingRows, error: existingError } = await serviceClient
    .from("subscriptions")
    .select("id,status,payment_provider,mercadopago_preapproval_id,current_period_end")
    .eq("user_id", userId)
    .in("status", ["waiting_authorization", "active", "payment_pending", "cancelled"])
    .order("created_at", { ascending: false })
    .limit(20);
  if (existingError) return errorResponse("Erro ao consultar assinatura.", 500);
  const existing = (existingRows ?? []).find((row) => {
    const paidUntil = row.current_period_end
      ? new Date(row.current_period_end).getTime()
      : 0;
    return row.status === "waiting_authorization" || paidUntil >= Date.now();
  });
  if (existing) {
    const paidUntil = existing.current_period_end
      ? new Date(existing.current_period_end).getTime()
      : 0;
    const reusablePending = existing.payment_provider === "mercado_pago" &&
      existing.status === "waiting_authorization";
    if (reusablePending && existing.mercadopago_preapproval_id) {
      return jsonResponse({
        subscriptionId: existing.id,
        providerSubscriptionId: existing.mercadopago_preapproval_id,
        status: "waiting_authorization",
      }, 202);
    }
    if (["active", "payment_pending"].includes(existing.status) || paidUntil >= Date.now()) {
      return errorResponse("Já existe uma assinatura ativa ou em andamento.", 409);
    }
  }

  const { data: plan, error: planError } = await serviceClient
    .from("plans")
    .select("id,name,subscription_type,price,is_active,mercadopago_preapproval_plan_id")
    .eq("id", body.planId)
    .maybeSingle();
  if (planError || !plan) return errorResponse("Plano não encontrado.", 404);
  if (!plan.is_active || plan.subscription_type !== "mensal") {
    return errorResponse("Este plano não está disponível para assinatura.", 409);
  }
  if (!plan.mercadopago_preapproval_plan_id) {
    return errorResponse("Plano ainda não publicado no Mercado Pago.", 409);
  }
  const { data: billingProfile } = await serviceClient.from("billing_profiles")
    .select("email")
    .eq("user_id", userId)
    .maybeSingle();
  const payerEmail = String(billingProfile?.email ?? auth.user.email ?? "");
  if (!payerEmail) return errorResponse("Usuário sem e-mail de cobrança.", 409);

  const pendingLocal = existing?.payment_provider === "mercado_pago" &&
    existing.status === "waiting_authorization" &&
    !existing.mercadopago_preapproval_id
    ? existing
    : null;
  if (existing && !pendingLocal) {
    await serviceClient.from("subscriptions")
      .update({ is_current: false, updated_at: new Date().toISOString() })
      .eq("id", existing.id);
  }

  let localId = pendingLocal?.id;
  if (!localId) {
    const { data, error: insertError } = await serviceClient
      .from("subscriptions")
      .insert({
        user_id: userId,
        plan_id: plan.id,
        badge_level: "bronze",
        plan_level_status: "bronze",
        is_current: true,
        status: "waiting_authorization",
        payment_access_status: "blocked",
        payment_provider: "mercado_pago",
        value_cents: Math.round(Number(plan.price) * 100),
        currency: "BRL",
        interval: "MONTHLY",
        metadata: { creation_source: "android_native_tokenization" },
      })
      .select("id,status")
      .single();
    if (insertError || !data) {
      return errorResponse("Não foi possível iniciar a assinatura.", 409);
    }
    localId = data.id;
  }

  try {
    const env = getMercadoPagoEnv();
    const mercadoPago = new MercadoPagoClient(env);
    const remote = await mercadoPago.createPreapproval({
      preapproval_plan_id: plan.mercadopago_preapproval_plan_id,
      reason: plan.name,
      external_reference: localId,
      payer_email: payerEmail,
      card_token_id: body.cardTokenId,
      status: "authorized",
      back_url: env.returnUrl,
    }, `vittaclube-subscription-${localId}`);
    const providerSubscriptionId = String(remote.id ?? "");
    if (!providerSubscriptionId) throw new Error("Assinatura sem identificador.");

    const { error: updateError } = await serviceClient
      .from("subscriptions")
      .update({
        mercadopago_preapproval_id: providerSubscriptionId,
        updated_at: new Date().toISOString(),
        metadata: {
          creation_source: "android_native_tokenization",
          provider_status: remote.status ?? null,
        },
      })
      .eq("id", localId);
    if (updateError) {
      // A recorrência externa já existe. O mesmo ID local mantém a mesma chave
      // de idempotência para uma repetição segura, sem criar uma órfã nova.
      return errorResponse("Assinatura criada; sincronização local pendente.", 503);
    }

    return jsonResponse({
      subscriptionId: localId,
      providerSubscriptionId,
      status: "waiting_authorization",
    }, 202);
  } catch (error) {
    const definitiveRejection = error instanceof MercadoPagoApiError &&
      error.status >= 400 && error.status < 500 && error.status !== 429;
    if (definitiveRejection) {
      await serviceClient.from("subscriptions").update({
        status: "rejected",
        payment_access_status: "blocked",
        is_current: false,
        rejected_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        metadata: { creation_source: "android_native_tokenization", creation_failed: true },
      }).eq("id", localId);
      return errorResponse("O Mercado Pago não autorizou a criação da assinatura.", 422);
    }
    // Timeout/5xx é ambíguo: preserva o mesmo registro e a mesma chave de
    // idempotência para que uma nova tentativa não duplique a recorrência.
    return errorResponse("Mercado Pago indisponível; tente novamente.", 503);
  }
});
