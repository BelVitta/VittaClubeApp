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

  const { data: subscription, error } = await client
    .from("subscriptions")
    .select("*")
    .eq("id", subscriptionId)
    .maybeSingle();
  if (error || !subscription) return errorResponse("Assinatura não encontrada.", 404);
  if (!canOperateSubscription(userData.user, subscription.user_id)) {
    return errorResponse("Sem permissão para cancelar esta assinatura.", 403);
  }

  const woovi = new WooviClient(getWooviEnv());
  await woovi.cancelSubscription(subscription.woovi_subscription_id ?? subscription.correlation_id);

  await client
    .from("subscriptions")
    .update({
      status: "cancelled",
      cancelled_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq("id", subscriptionId);

  await client.from("subscription_access_events").insert({
    subscription_id: subscriptionId,
    user_id: subscription.user_id,
    from_status: subscription.status,
    to_status: "cancelled",
    from_access_status: subscription.payment_access_status,
    to_access_status: subscription.payment_access_status,
    reason: reason ?? "Cancelamento solicitado",
    source: "operator",
  });

  return jsonResponse({ ok: true, subscriptionId, status: "cancelled" });
});

function canOperateSubscription(user: any, subscriptionUserId: string): boolean {
  if (user.id === subscriptionUserId) return true;
  const role = user.user_metadata?.role ?? user.app_metadata?.role;
  return ["admin", "financeiro", "super_admin"].includes(role);
}
