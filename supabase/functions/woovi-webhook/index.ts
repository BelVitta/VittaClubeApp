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
      if (hasUnexpectedChargeValue(event)) {
        await upsertCharge(client, event, "expired");
        return updateSubscription(client, event, {
          status: "blocked",
          payment_access_status: "blocked",
          blocked_at: new Date().toISOString(),
        }, "Cobrança Pix com valor divergente.");
      }
      if (await upsertCharge(client, event, "paid")) return;
      return markChargeCompleted(client, event);
    case "charge_rejected":
      await upsertCharge(client, event, "expired");
      return markPaymentPending(client, event);
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
    .select("id,user_id,status,payment_access_status,current_period_start,current_period_end,is_current")
    .eq("correlation_id", event.subscriptionCorrelationID)
    .maybeSingle();

  if (!before) return;

  const now = new Date();
  const currentPeriodEnd = before.current_period_end
    ? new Date(before.current_period_end)
    : null;
  const hasPaidPeriod = !!currentPeriodEnd && currentPeriodEnd.getTime() > now.getTime();
  const effectivePatch: Record<string, unknown> = { ...patch };

  // A late creation/authorization notification must never roll a paid
  // subscription back to a waiting state.
  if (event.processedAs === "subscription_created" &&
      ["active", "payment_pending", "cancelled"].includes(String(before.status)) &&
      hasPaidPeriod) {
    return;
  }
  if (event.processedAs === "subscription_authorized" &&
      ["active", "payment_pending", "cancelled"].includes(String(before.status))) {
    delete effectivePatch.status;
    delete effectivePatch.payment_access_status;
  }

  // A rejection after a paid period is a renewal problem, not a first-time
  // rejection. A first failed charge must remain blocked.
  if (["subscription_rejected", "charge_try_rejected", "charge_rejected"].includes(event.processedAs)) {
    if (hasPaidPeriod) {
      effectivePatch.status = "payment_pending";
      effectivePatch.payment_access_status = "warning_pending";
      delete effectivePatch.blocked_at;
    } else {
      effectivePatch.status = event.processedAs === "subscription_rejected"
        ? "rejected"
        : "blocked";
      effectivePatch.payment_access_status = "blocked";
      effectivePatch.blocked_at = now.toISOString();
    }
  }

  if (event.processedAs === "subscription_cancelled") {
    effectivePatch.status = "cancelled";
    effectivePatch.payment_access_status = hasPaidPeriod ? "allowed" : "blocked";
    effectivePatch.is_current = hasPaidPeriod;
  }

  if (Object.keys(effectivePatch).length === 0) return;

  const { error: updateError } = await client
    .from("subscriptions")
    .update({ ...effectivePatch, updated_at: now.toISOString() })
    .eq("correlation_id", event.subscriptionCorrelationID);
  if (updateError) throw updateError;

  const toStatus = String(effectivePatch.status ?? before.status);
  const toAccessStatus = String(
    effectivePatch.payment_access_status ?? before.payment_access_status,
  );
  const changed =
    before.status !== toStatus ||
    before.payment_access_status !== toAccessStatus;

  if (!changed) return;

  const { error: auditError } = await client.from("subscription_access_events").insert({
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
  if (auditError) throw auditError;
}

async function upsertCharge(client: any, event: any, status: string): Promise<boolean> {
  if (!event.chargeCorrelationID || !event.subscriptionCorrelationID) return false;
  const { data: subscription } = await client
    .from("subscriptions")
    .select("id,user_id")
    .eq("correlation_id", event.subscriptionCorrelationID)
    .maybeSingle();
  if (!subscription) return false;

  const { data: existing, error: existingError } = await client
    .from("subscription_charges")
    .select("status")
    .eq("correlation_id", event.chargeCorrelationID)
    .maybeSingle();
  if (existingError) throw existingError;
  // A late retry event cannot downgrade an already paid charge. Returning
  // true tells the caller that no entitlement transition is needed.
  if (existing?.status === "paid" && status !== "paid") return true;
  if (existing?.status === "paid" && status === "paid") return true;

  const paidAt = status === "paid" ? paymentDate(event) : null;
  const { error } = await client.from("subscription_charges").upsert({
    subscription_id: subscription.id,
    user_id: subscription.user_id,
    correlation_id: event.chargeCorrelationID,
    subscription_correlation_id: event.subscriptionCorrelationID,
    value_cents: Number(event.charge?.value ?? 3490),
    status,
    cycle_reference: (paidAt ?? new Date()).toISOString().slice(0, 7),
    paid_at: paidAt?.toISOString() ?? null,
    raw_latest_event: event.raw,
    updated_at: new Date().toISOString(),
  }, { onConflict: "correlation_id" });
  if (error) throw error;
  return false;
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
  const { error: attemptError } = await client.from("subscription_charge_attempts").upsert({
    subscription_charge_id: charge.id,
    attempt_number: attemptNumber,
    status,
    requested_at: status === "requested" ? new Date().toISOString() : null,
    rejected_at: status === "rejected" ? new Date().toISOString() : null,
    raw_event: event.raw,
  }, { onConflict: "subscription_charge_id,attempt_number" });
  if (attemptError) throw attemptError;
  const { error: chargeError } = await client
    .from("subscription_charges")
    .update({ attempt_count: attemptNumber, status: status === "rejected" ? "retrying" : "created" })
    .eq("id", charge.id);
  if (chargeError) throw chargeError;
}

async function markPaymentPending(client: any, event: any) {
  if (event.chargeCorrelationID) {
    const { data: charge, error } = await client
      .from("subscription_charges")
      .select("status")
      .eq("correlation_id", event.chargeCorrelationID)
      .maybeSingle();
    if (error) throw error;
    // A delayed rejection/attempt event must not downgrade a charge that was
    // already confirmed as paid.
    if (charge?.status === "paid") return;
  }
  await updateSubscription(client, event, {},
    event.processedAs === "charge_rejected"
      ? "Cobrança Pix expirada sem pagamento; período pago preservado quando vigente."
      : "Tentativa de cobrança Pix recusada; recuperação automática iniciada.");
}

async function markChargeCompleted(client: any, event: any) {
  const { data: before, error } = await client
    .from("subscriptions")
    .select("current_period_start,current_period_end,status")
    .eq("correlation_id", event.subscriptionCorrelationID)
    .maybeSingle();
  if (error) throw error;
  if (!before) return;

  const paidAt = paymentDate(event) ?? new Date();
  const previousStart = before.current_period_start
    ? new Date(before.current_period_start)
    : null;
  // An approved event older than the period already applied is a late or
  // duplicated notification and must not move entitlement backwards.
  if (previousStart && paidAt.getTime() <= previousStart.getTime()) return;

  const candidateEnd = nextMonthIso(paidAt);
  const previousEnd = before.current_period_end
    ? new Date(before.current_period_end)
    : null;
  const periodEnd = previousEnd && previousEnd.getTime() > Date.parse(candidateEnd)
    ? previousEnd
    : new Date(candidateEnd);

  await updateSubscription(client, event, {
    status: "active",
    payment_access_status: "allowed",
    current_period_start: paidAt.toISOString(),
    current_period_end: periodEnd.toISOString(),
    next_billing_date: periodEnd.toISOString().slice(0, 10),
  }, "Cobrança Pix Automático confirmada.");
}

function nextMonthIso(date: Date): string {
  const next = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, date.getUTCDate()));
  return next.toISOString();
}

function paymentDate(event: any): Date | null {
  const charge = event.charge ?? {};
  const raw = event.raw ?? {};
  const candidates = [
    charge.paidAt,
    raw.paidAt,
    raw.dateGenerateCharge,
    charge.updatedAt,
    charge.createdAt,
    raw.createdAt,
  ];
  for (const value of candidates) {
    if (!value) continue;
    const date = new Date(String(value));
    if (!Number.isNaN(date.getTime())) return date;
  }
  return null;
}

function hasUnexpectedChargeValue(event: any): boolean {
  const value = Number(event.charge?.value ?? event.raw?.value);
  return Number.isFinite(value) && value !== 3490;
}
