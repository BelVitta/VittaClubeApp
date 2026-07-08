import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { errorResponse, jsonResponse } from "../_shared/http.ts";
import { WooviClient } from "../_shared/woovi/client.ts";
import { getWooviEnv } from "../_shared/woovi/env.ts";

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

  const { data: local, error } = await client
    .from("subscriptions")
    .select("*")
    .eq("id", subscriptionId)
    .maybeSingle();
  if (error || !local) return errorResponse("Assinatura não encontrada.", 404);
  if (!canReconcileSubscription(userData.user, local.user_id)) {
    return errorResponse("Sem permissão para reconciliar esta assinatura.", 403);
  }

  const woovi = new WooviClient(getWooviEnv());
  const remote = await woovi.getSubscription(local.woovi_subscription_id ?? local.correlation_id);
  const remoteSubscription = remote.subscription ?? remote;
  const before = local.status;
  const after = mapRemoteStatus(remoteSubscription.status ?? before);

  await client
    .from("subscriptions")
    .update({
      status: after,
      payment_access_status: after === "active" ? "allowed" : local.payment_access_status,
      last_reconciled_at: new Date().toISOString(),
      metadata: { ...(local.metadata ?? {}), lastWooviReconciliation: remoteSubscription },
    })
    .eq("id", subscriptionId);

  return jsonResponse({
    subscriptionId,
    statusBefore: before,
    statusAfter: after,
    lastReconciledAt: new Date().toISOString(),
  });
});

function mapRemoteStatus(status: string): string {
  const normalized = status.toUpperCase();
  if (normalized.includes("AUTHORIZED") || normalized.includes("ACTIVE")) return "active";
  if (normalized.includes("REJECTED")) return "rejected";
  if (normalized.includes("CANCELLED") || normalized.includes("CANCELED")) return "cancelled";
  return "waiting_authorization";
}

function canReconcileSubscription(user: any, subscriptionUserId: string): boolean {
  if (user.id === subscriptionUserId) return true;
  const role = user.user_metadata?.role ?? user.app_metadata?.role;
  return ["admin", "financeiro", "super_admin"].includes(role);
}
