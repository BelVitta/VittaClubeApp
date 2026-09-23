import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { enforceRateLimit, errorResponse, jsonResponse } from "../_shared/http.ts";
import { WooviClient } from "../_shared/woovi/client.ts";
import { getWooviEnv } from "../_shared/woovi/env.ts";
import { hasBillingAdminRole } from "../_shared/mercadopago/auth.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  const authHeader = request.headers.get("Authorization");
  if (!authHeader) return errorResponse("Não autenticado.", 401);

  const { subscriptionId, reason } = await request.json();
  if (!subscriptionId) return errorResponse("subscriptionId é obrigatório.", 400);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const userClient = createClient(
    supabaseUrl,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const client = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return errorResponse("Não autenticado.", 401);

  const limited = await enforceRateLimit(userClient, "cancel_woovi_subscription", 5);
  if (limited) return limited;

  const { data: subscription, error } = await client
    .from("subscriptions")
    .select("*")
    .eq("id", subscriptionId)
    .maybeSingle();
  if (error || !subscription) return errorResponse("Assinatura não encontrada.", 404);
  const isAdmin = await hasBillingAdminRole(userClient, userData.user.id);
  if (userData.user.id !== subscription.user_id && !isAdmin) {
    return errorResponse("Sem permissão para cancelar esta assinatura.", 403);
  }

  const woovi = new WooviClient(getWooviEnv());
  await woovi.cancelSubscription(subscription.woovi_subscription_id ?? subscription.correlation_id);

  const now = new Date();
  const hasPaidPeriod = !!subscription.current_period_end &&
    new Date(subscription.current_period_end).getTime() > now.getTime();
  const { error: updateError } = await client
    .from("subscriptions")
    .update({
      status: "cancelled",
      cancelled_at: now.toISOString(),
      cancellation_reason_text: reason ?? null,
      payment_access_status: hasPaidPeriod ? "allowed" : "blocked",
      is_current: hasPaidPeriod,
      updated_at: now.toISOString(),
    })
    .eq("id", subscriptionId);
  if (updateError) return errorResponse("A recorrência foi cancelada, mas não foi possível atualizar o acesso local.", 500);

  const { error: auditError } = await client.from("subscription_access_events").insert({
    subscription_id: subscriptionId,
    user_id: subscription.user_id,
    from_status: subscription.status,
    to_status: "cancelled",
    from_access_status: subscription.payment_access_status,
    to_access_status: hasPaidPeriod ? "allowed" : "blocked",
    reason: reason ?? "Cancelamento solicitado",
    source: "operator",
  });
  if (auditError) return errorResponse("Cancelamento salvo, mas não foi possível registrar a auditoria.", 500);

  return jsonResponse({
    ok: true,
    subscriptionId,
    status: "cancelled",
    accessUntil: hasPaidPeriod ? subscription.current_period_end : null,
  });
});
