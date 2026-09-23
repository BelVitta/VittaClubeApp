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

  const { subscriptionId } = await request.json();
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

  const limited = await enforceRateLimit(userClient, "reconcile_woovi_subscription", 10);
  if (limited) return limited;

  const { data: local, error } = await client
    .from("subscriptions")
    .select("*")
    .eq("id", subscriptionId)
    .maybeSingle();
  if (error || !local) return errorResponse("Assinatura não encontrada.", 404);
  const isBillingAdmin = await hasBillingAdminRole(userClient, userData.user.id);
  if (userData.user.id !== local.user_id && !isBillingAdmin) {
    return errorResponse("Sem permissão para reconciliar esta assinatura.", 403);
  }

  const woovi = new WooviClient(getWooviEnv());
  const remote = await woovi.getSubscription(local.woovi_subscription_id ?? local.correlation_id);
  const remoteSubscription = remote.subscription ?? remote;
  const before = local.status;
  const now = new Date();
  const currentPeriodEnd = local.current_period_end
    ? new Date(local.current_period_end)
    : null;
  const hasPaidPeriod = !!currentPeriodEnd && currentPeriodEnd.getTime() > now.getTime();
  let after = mapRemoteStatus(remoteSubscription.status ?? before);
  let access = local.payment_access_status;

  // Authorization of the recurring contract is not proof that the first
  // monthly charge was paid. Access requires a paid local period.
  if (after === "active" && !hasPaidPeriod) {
    after = "waiting_authorization";
    access = "blocked";
  } else if (after === "active" && hasPaidPeriod) {
    access = "allowed";
  } else if (!hasPaidPeriod && currentPeriodEnd) {
    after = "blocked";
    access = "blocked";
  }
  if (before === "cancelled") {
    after = "cancelled";
    access = hasPaidPeriod ? "allowed" : "blocked";
  }

  const { error: updateError } = await client
    .from("subscriptions")
    .update({
      status: after,
      payment_access_status: access,
      // Keep an authorization operation current until it reaches a terminal
      // state, even though access remains blocked before the first payment.
      is_current: after === "waiting_authorization" || access !== "blocked",
      last_reconciled_at: now.toISOString(),
      metadata: { ...(local.metadata ?? {}), lastWooviReconciliation: remoteSubscription },
    })
    .eq("id", subscriptionId);
  if (updateError) return errorResponse("Não foi possível salvar a reconciliação.", 500);

  return jsonResponse({
    subscriptionId,
    statusBefore: before,
    statusAfter: after,
    lastReconciledAt: now.toISOString(),
  });
});

function mapRemoteStatus(status: string): string {
  const normalized = status.toUpperCase();
  if (normalized.includes("AUTHORIZED") || normalized.includes("ACTIVE")) return "active";
  if (normalized.includes("REJECTED")) return "rejected";
  if (normalized.includes("CANCELLED") || normalized.includes("CANCELED")) return "cancelled";
  return "waiting_authorization";
}
