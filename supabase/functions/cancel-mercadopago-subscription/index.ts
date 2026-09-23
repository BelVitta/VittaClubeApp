import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { enforceRateLimit, errorResponse, jsonResponse } from "../_shared/http.ts";
import { hasBillingAdminRole } from "../_shared/mercadopago/auth.ts";
import { MercadoPagoClient } from "../_shared/mercadopago/client.ts";
import { getMercadoPagoEnv } from "../_shared/mercadopago/env.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return errorResponse("Method not allowed", 405);
  const authHeader = request.headers.get("Authorization");
  if (!authHeader) return errorResponse("Não autenticado.", 401);
  let body: { subscriptionId?: string; reason?: string };
  try {
    body = await request.json();
  } catch (_) {
    return errorResponse("Payload inválido.", 400);
  }
  if (!body.subscriptionId) return errorResponse("subscriptionId é obrigatório.", 400);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const serviceClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: auth, error: authError } = await userClient.auth.getUser();
  if (authError || !auth.user) return errorResponse("Não autenticado.", 401);
  const limited = await enforceRateLimit(userClient, "cancel_mercadopago_subscription", 5);
  if (limited) return limited;

  const { data: subscription, error } = await serviceClient
    .from("subscriptions").select("*").eq("id", body.subscriptionId).maybeSingle();
  if (error || !subscription) return errorResponse("Assinatura não encontrada.", 404);
  const admin = await hasBillingAdminRole(userClient, auth.user.id);
  if (subscription.user_id !== auth.user.id && !admin) {
    return errorResponse("Sem permissão para cancelar esta assinatura.", 403);
  }
  if (subscription.payment_provider !== "mercado_pago" ||
    !subscription.mercadopago_preapproval_id) {
    return errorResponse("Assinatura não pertence ao Mercado Pago.", 409);
  }

  try {
    const mercadoPago = new MercadoPagoClient(getMercadoPagoEnv());
    await mercadoPago.updatePreapproval(subscription.mercadopago_preapproval_id, {
      status: "cancelled",
    });
  } catch (_) {
    return errorResponse("Não foi possível cancelar a recorrência no Mercado Pago.", 502);
  }

  const now = new Date();
  const accessUntil = subscription.current_period_end as string | null;
  const hasPaidPeriod = !!accessUntil && new Date(accessUntil).getTime() >= now.getTime();
  await serviceClient.from("subscriptions").update({
    status: "cancelled",
    cancelled_at: now.toISOString(),
    cancellation_reason_text: body.reason ?? null,
    payment_access_status: hasPaidPeriod ? "allowed" : "blocked",
    is_current: hasPaidPeriod,
    updated_at: now.toISOString(),
  }).eq("id", subscription.id);

  await serviceClient.from("subscription_access_events").insert({
    subscription_id: subscription.id,
    user_id: subscription.user_id,
    from_status: subscription.status,
    to_status: "cancelled",
    from_access_status: subscription.payment_access_status,
    to_access_status: hasPaidPeriod ? "allowed" : "blocked",
    reason: body.reason ?? "Cancelamento solicitado",
    source: admin ? "billing_admin" : "member",
    metadata: { provider: "mercado_pago", access_until: accessUntil },
  });

  return jsonResponse({
    subscriptionId: subscription.id,
    status: "cancelled",
    accessUntil: hasPaidPeriod ? accessUntil : null,
  });
});
