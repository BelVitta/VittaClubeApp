import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { enforceRateLimit, errorResponse, jsonResponse } from "../_shared/http.ts";
import { hasBillingAdminRole } from "../_shared/mercadopago/auth.ts";

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

  const url = Deno.env.get("SUPABASE_URL")!;
  const userClient = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const serviceClient = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: auth, error: authError } = await userClient.auth.getUser();
  if (authError || !auth.user) return errorResponse("Não autenticado.", 401);
  const limited = await enforceRateLimit(userClient, "cancel_local_subscription", 5);
  if (limited) return limited;
  const { data: subscription } = await serviceClient.from("subscriptions")
    .select("*").eq("id", body.subscriptionId).maybeSingle();
  if (!subscription) return errorResponse("Assinatura não encontrada.", 404);
  const admin = await hasBillingAdminRole(userClient, auth.user.id);
  if (subscription.user_id !== auth.user.id && !admin) {
    return errorResponse("Sem permissão para cancelar esta assinatura.", 403);
  }
  if (["mercado_pago", "woovi"].includes(subscription.payment_provider)) {
    return errorResponse("Use o cancelamento específico do provedor.", 409);
  }
  const now = new Date().toISOString();
  await serviceClient.from("subscriptions").update({
    status: "cancelled",
    payment_access_status: "blocked",
    cancelled_at: now,
    cancellation_reason_text: body.reason ?? null,
    is_current: false,
    updated_at: now,
  }).eq("id", subscription.id);
  return jsonResponse({ subscriptionId: subscription.id, status: "cancelled", accessUntil: null });
});
