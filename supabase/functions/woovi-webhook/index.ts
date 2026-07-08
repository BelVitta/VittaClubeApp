import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { errorResponse, jsonResponse } from "../_shared/http.ts";
import { getWooviEnv } from "../_shared/woovi/env.ts";
import { normalizeWooviEvent } from "../_shared/woovi/event_mapper.ts";
import { verifyWooviHmac } from "../_shared/woovi/hmac.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  const rawBody = await request.text();
  const env = getWooviEnv();
  const signature = request.headers.get("x-webhook-signature") ??
    request.headers.get("X-Woovi-Signature") ??
    request.headers.get("X-OpenPix-Signature");
  const validSignature = await verifyWooviHmac(
    rawBody,
    signature,
    env.webhookSecret,
  );

  if (!validSignature) {
    return errorResponse("Assinatura do webhook inválida.", 401);
  }

  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(rawBody);
  } catch (_) {
    return errorResponse("Payload inválido.", 400);
  }

  const event = await normalizeWooviEvent(payload);
  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { error: eventInsertError } = await serviceClient
    .from("woovi_webhook_events")
    .insert({
      event_id: event.eventId,
      event_type: event.eventType,
      subscription_correlation_id: event.subscriptionCorrelationID,
      charge_correlation_id: event.chargeCorrelationID,
      signature_valid: true,
      processing_status: "received",
      payload,
    });

  if (eventInsertError?.code === "23505") {
    return jsonResponse({
      ok: true,
      deduplicated: true,
      eventId: event.eventId,
      processedAs: event.processedAs,
    });
  }

  if (eventInsertError) {
    return errorResponse(`Erro ao registrar webhook: ${eventInsertError.message}`, 500);
  }

  try {
    await processEvent(serviceClient, event);
    await serviceClient
      .from("woovi_webhook_events")
      .update({ processing_status: "processed", processed_at: new Date().toISOString() })
      .eq("event_id", event.eventId);

    return jsonResponse({
      ok: true,
      deduplicated: false,
      eventId: event.eventId,
      processedAs: event.processedAs,
    });
  } catch (error) {
    await serviceClient
      .from("woovi_webhook_events")
      .update({
        processing_status: "failed",
        processing_error: String(error),
        processed_at: new Date().toISOString(),
      })
      .eq("event_id", event.eventId);
    return errorResponse(`Erro ao processar webhook: ${String(error)}`, 500);
  }
});

async function processEvent(client: any, event: any) {
  switch (event.processedAs) {
    case "subscription_created":
      return updateSubscription(client, event, {
        status: "waiting_authorization",
        payment_access_status: "blocked",
      }, "Contrato Pix Automático criado.");
    case "subscription_authorized":
      return updateSubscription(client, event, {
        status: "waiting_authorization",
        payment_access_status: "blocked",
        authorized_at: new Date().toISOString(),
      }, "Autorização Pix Automático aprovada.");
    case "subscription_rejected":
      return updateSubscription(client, event, {
        status: "rejected",
        payment_access_status: "blocked",
        rejected_at: new Date().toISOString(),
      }, "Autorização Pix Automático recusada.");
    case "subscription_cancelled":
      return updateSubscription(client, event, {
        status: "cancelled",
        cancelled_at: new Date().toISOString(),
      }, "Recorrência Pix Automático cancelada.");
    case "charge_created":
      return upsertCharge(client, event, "created");
    case "charge_try_requested":
      return upsertAttempt(client, event, "requested");
    case "charge_try_rejected":
      await upsertAttempt(client, event, "rejected");
      return markPaymentPending(client, event);
    case "charge_completed":
      await upsertCharge(client, event, "paid");
      return markChargeCompleted(client, event);
    case "charge_rejected":
      await upsertCharge(client, event, "expired");
      return updateSubscription(client, event, {
        status: "blocked",
        payment_access_status: "blocked",
        blocked_at: new Date().toISOString(),
      }, "Cobrança expirada sem pagamento.");
    default:
      return;
  }
}

async function updateSubscription(
  client: any,
  event: any,
  patch: Record<string, unknown>,
  reason = "Evento Woovi processado.",
) {
  if (!event.subscriptionCorrelationID) return;
  const { data: before } = await client
    .from("subscriptions")
    .select("id,user_id,status,payment_access_status")
    .eq("correlation_id", event.subscriptionCorrelationID)
    .maybeSingle();

  if (!before) return;

  await client
    .from("subscriptions")
    .update({ ...patch, updated_at: new Date().toISOString() })
    .eq("correlation_id", event.subscriptionCorrelationID);

  const toStatus = String(patch.status ?? before.status);
  const toAccessStatus = String(
    patch.payment_access_status ?? before.payment_access_status,
  );
  const changed =
    before.status !== toStatus ||
    before.payment_access_status !== toAccessStatus;

  if (!changed) return;

  await client.from("subscription_access_events").insert({
    subscription_id: before.id,
    user_id: before.user_id,
    from_status: before.status,
    to_status: toStatus,
    from_access_status: before.payment_access_status,
    to_access_status: toAccessStatus,
    reason,
    source: "woovi_webhook",
    metadata: {
      event_id: event.eventId,
      event_type: event.eventType,
      processed_as: event.processedAs,
      charge_correlation_id: event.chargeCorrelationID,
    },
  });
}

async function upsertCharge(client: any, event: any, status: string) {
  if (!event.chargeCorrelationID || !event.subscriptionCorrelationID) return;
  const { data: subscription } = await client
    .from("subscriptions")
    .select("id,user_id")
    .eq("correlation_id", event.subscriptionCorrelationID)
    .maybeSingle();
  if (!subscription) return;

  await client.from("subscription_charges").upsert({
    subscription_id: subscription.id,
    user_id: subscription.user_id,
    correlation_id: event.chargeCorrelationID,
    subscription_correlation_id: event.subscriptionCorrelationID,
    value_cents: Number(event.charge?.value ?? 3490),
    status,
    cycle_reference: new Date().toISOString().slice(0, 7),
    paid_at: status === "paid" ? new Date().toISOString() : null,
    raw_latest_event: event.raw,
    updated_at: new Date().toISOString(),
  }, { onConflict: "correlation_id" });
}

async function upsertAttempt(client: any, event: any, status: string) {
  if (!event.chargeCorrelationID) return;
  const { data: charge } = await client
    .from("subscription_charges")
    .select("id,attempt_count")
    .eq("correlation_id", event.chargeCorrelationID)
    .maybeSingle();
  if (!charge) return;
  const attemptNumber = Math.min((charge.attempt_count ?? 0) + 1, 3);
  await client.from("subscription_charge_attempts").upsert({
    subscription_charge_id: charge.id,
    attempt_number: attemptNumber,
    status,
    requested_at: status === "requested" ? new Date().toISOString() : null,
    rejected_at: status === "rejected" ? new Date().toISOString() : null,
    raw_event: event.raw,
  }, { onConflict: "subscription_charge_id,attempt_number" });
  await client
    .from("subscription_charges")
    .update({ attempt_count: attemptNumber, status: status === "rejected" ? "retrying" : "created" })
    .eq("id", charge.id);
}

async function markPaymentPending(client: any, event: any) {
  await updateSubscription(client, event, {
    status: "payment_pending",
    payment_access_status: "warning_pending",
  }, "Primeira falha de cobrança; recuperação automática iniciada.");
}

async function markChargeCompleted(client: any, event: any) {
  await updateSubscription(client, event, {
    status: "active",
    payment_access_status: "allowed",
    current_period_start: new Date().toISOString(),
    current_period_end: nextMonthIso(new Date()),
    next_billing_date: nextMonthIso(new Date()).slice(0, 10),
  }, "Cobrança Pix Automático confirmada.");
}

function nextMonthIso(date: Date): string {
  const next = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, date.getUTCDate()));
  return next.toISOString();
}
