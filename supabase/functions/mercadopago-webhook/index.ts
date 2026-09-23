import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { errorResponse, jsonResponse } from "../_shared/http.ts";
import { getMercadoPagoEnv } from "../_shared/mercadopago/env.ts";
import { verifyMercadoPagoSignature } from "../_shared/mercadopago/webhook_signature.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return errorResponse("Method not allowed", 405);
  let payload: Record<string, unknown>;
  try {
    payload = await request.json();
  } catch (_) {
    return errorResponse("Payload inválido.", 400);
  }

  const url = new URL(request.url);
  const data = payload.data && typeof payload.data === "object"
    ? payload.data as Record<string, unknown>
    : {};
  const resourceId = String(data.id ?? url.searchParams.get("data.id") ?? "");
  const requestId = request.headers.get("x-request-id");
  let env;
  try {
    env = getMercadoPagoEnv();
  } catch (_) {
    return errorResponse("Webhook não configurado.", 503);
  }
  const valid = await verifyMercadoPagoSignature({
    signatureHeader: request.headers.get("x-signature"),
    requestId,
    dataId: resourceId,
    secret: env.webhookSecret,
  });
  if (!valid) return errorResponse("Assinatura do webhook inválida.", 401);

  const topic = String(payload.type ?? url.searchParams.get("type") ?? "unknown");
  const action = payload.action == null ? null : String(payload.action);
  const notificationId = String(payload.id ?? "");
  const eventKey = notificationId
    ? `${topic}:${notificationId}`
    : `${topic}:${resourceId}:${requestId}`;
  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { error } = await serviceClient.from("mercadopago_webhook_events").insert({
    event_key: eventKey,
    request_id: requestId,
    topic,
    action,
    resource_id: resourceId,
    signature_valid: true,
    processing_status: "received",
    payload,
  });
  if (error?.code === "23505") return jsonResponse({ ok: true, deduplicated: true });
  if (error) return errorResponse("Falha ao registrar evento.", 500);
  return jsonResponse({ ok: true, queued: true }, 200);
});

