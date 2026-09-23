import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { errorResponse, jsonResponse } from "../_shared/http.ts";
import { hasBillingAdminRole } from "../_shared/mercadopago/auth.ts";
import { MercadoPagoClient } from "../_shared/mercadopago/client.ts";
import { getMercadoPagoEnv } from "../_shared/mercadopago/env.ts";
import {
  accessStateForCharge,
  addUtcMonth,
  canonicalKind,
  isNewerPaidPeriod,
  normalizeCanonicalCharge,
  type CanonicalCharge,
} from "../_shared/mercadopago/state.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return errorResponse("Method not allowed", 405);
  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  if (!await isAuthorized(request)) return errorResponse("Não autorizado.", 401);

  const mercadoPago = new MercadoPagoClient(getMercadoPagoEnv());
  const summary = {
    processed: 0,
    ignored: 0,
    failed: 0,
    priceItems: 0,
    blocked: 0,
    remoteSubscriptions: 0,
  };
  const now = new Date();
  const { data: readyEvents, error: readyError } = await serviceClient
    .from("mercadopago_webhook_events")
    .select("*")
    .in("processing_status", ["received", "failed"])
    .lte("next_attempt_at", now.toISOString())
    .order("received_at", { ascending: true })
    .limit(50);
  if (readyError) return errorResponse("Não foi possível ler a fila de Webhooks.", 500);

  const { data: stuckEvents, error: stuckError } = await serviceClient
    .from("mercadopago_webhook_events")
    .select("*")
    .eq("processing_status", "processing")
    .or(`lease_until.is.null,lease_until.lt.${now.toISOString()}`)
    .order("received_at", { ascending: true })
    .limit(50);
  if (stuckError) return errorResponse("Não foi possível recuperar a fila de Webhooks.", 500);

  const events = [...(readyEvents ?? []), ...(stuckEvents ?? [])]
    .sort((a, b) => String(a.received_at).localeCompare(String(b.received_at)));

  for (const event of events) {
    const leaseUntil = new Date(Date.now() + 5 * 60 * 1000).toISOString();
    let claimQuery = serviceClient.from("mercadopago_webhook_events")
      .update({
      processing_status: "processing",
      attempt_count: Number(event.attempt_count ?? 0) + 1,
      processing_started_at: now.toISOString(),
      lease_until: leaseUntil,
    }).eq("id", event.id);
    if (event.processing_status === "processing") {
      claimQuery = claimQuery.eq("processing_status", "processing")
        .or(`lease_until.is.null,lease_until.lt.${now.toISOString()}`);
    } else {
      claimQuery = claimQuery.eq("processing_status", event.processing_status)
        .lte("next_attempt_at", now.toISOString());
    }
    const { data: claimed, error: claimError } = await claimQuery
      .select("*")
      .maybeSingle();
    if (claimError) throw claimError;
    // Another worker owns this event, or it was completed between the queue
    // read and the claim. Never process it twice.
    if (!claimed) continue;
    try {
      const outcome = await processEvent(serviceClient, mercadoPago, claimed);
      const now = new Date().toISOString();
      const { error: finishError } = await serviceClient.from("mercadopago_webhook_events").update({
        processing_status: outcome === "ignored" ? "ignored" : "processed",
        processing_error: outcome === "ignored" ? "Evento sem alteração aplicável." : null,
        processed_at: now,
        processing_started_at: null,
        lease_until: null,
      }).eq("id", claimed.id).eq("processing_status", "processing");
      if (finishError) throw finishError;
      outcome === "ignored" ? summary.ignored++ : summary.processed++;
    } catch (_) {
      summary.failed++;
      const attempts = Number(claimed.attempt_count ?? 0);
      const next = new Date(Date.now() + Math.min(3600, 30 * (2 ** attempts)) * 1000);
      await serviceClient.from("mercadopago_webhook_events").update({
        processing_status: "failed",
        processing_error: "Falha temporária ao consultar/processar recurso canônico.",
        next_attempt_at: next.toISOString(),
        processing_started_at: null,
        lease_until: null,
      }).eq("id", claimed.id).eq("processing_status", "processing");
    }
  }

  summary.remoteSubscriptions = await reconcileRemoteSubscriptions(serviceClient, mercadoPago);
  summary.priceItems = await processPriceChanges(serviceClient, mercadoPago);
  summary.blocked = await blockExpiredPeriods(serviceClient);
  return jsonResponse({ ok: true, ...summary });
});

async function isAuthorized(request: Request): Promise<boolean> {
  const expected = Deno.env.get("MERCADOPAGO_CRON_SECRET") ?? "";
  if (expected && request.headers.get("x-cron-secret") === expected) return true;
  const authHeader = request.headers.get("Authorization");
  if (!authHeader) return false;
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data, error } = await userClient.auth.getUser();
  return !error && !!data.user && await hasBillingAdminRole(userClient, data.user.id);
}

async function processEvent(client: any, mercadoPago: MercadoPagoClient, event: any) {
  const kind = canonicalKind(event.topic);
  if (kind === "unknown" || kind === "plan") return "ignored";
  if (kind === "preapproval") {
    const remote = await mercadoPago.getPreapproval(event.resource_id);
    return await applyPreapproval(client, remote);
  }

  let charge: CanonicalCharge | null;
  if (kind === "authorized_payment") {
    const remote = await mercadoPago.getAuthorizedPayment(event.resource_id);
    charge = normalizeCanonicalCharge(remote, event.resource_id);
    if (!charge) {
      const paymentId = String(remote.payment_id ?? "");
      if (!paymentId) return "ignored";
      charge = normalizeCanonicalCharge(
        await mercadoPago.getPayment(paymentId),
        event.resource_id,
      );
    }
  } else {
    charge = normalizeCanonicalCharge(await mercadoPago.getPayment(event.resource_id));
  }
  if (!charge) return "ignored";
  return await applyCharge(client, charge);
}

// Webhooks are an optimization, not the source of truth. Periodically scan
// provider-linked subscriptions as well so a dropped notification is recovered.
async function reconcileRemoteSubscriptions(client: any, mercadoPago: MercadoPagoClient) {
  let offset = 0;
  let scanned = 0;
  while (offset < 1000) {
    const { data: subscriptions, error } = await client
      .from("subscriptions")
      .select("id,mercadopago_preapproval_id")
      .eq("payment_provider", "mercado_pago")
      .not("mercadopago_preapproval_id", "is", null)
      .in("status", ["waiting_authorization", "active", "payment_pending", "cancelled", "blocked"])
      .order("created_at", { ascending: true })
      .range(offset, offset + 49);
    if (error) throw error;
    if (!subscriptions?.length) break;

    for (const subscription of subscriptions) {
      scanned++;
      try {
        const preapprovalId = String(subscription.mercadopago_preapproval_id);
        const remote = await mercadoPago.getPreapproval(preapprovalId);
        await applyPreapproval(client, remote);

        let chargeOffset = 0;
        while (chargeOffset < 1000) {
          const search = await mercadoPago.searchAuthorizedPayments(preapprovalId, chargeOffset);
          const results = Array.isArray(search.results)
            ? search.results as Record<string, unknown>[]
            : [];
          const charges = results
            .map((item) => normalizeCanonicalCharge(item, String(item.id ?? "")))
            .filter((item): item is CanonicalCharge => item != null)
            .sort((a, b) => String(a.paidAt ?? "").localeCompare(String(b.paidAt ?? "")));
          for (const charge of charges) await applyCharge(client, charge);
          chargeOffset += results.length;
          const total = Number((search.paging as Record<string, unknown> | undefined)?.total ?? 0);
          if (results.length < 20 || (total > 0 && chargeOffset >= total)) break;
        }
      } catch (_) {
        // A single provider failure must not prevent other subscriptions from
        // being reconciled during the same scheduled run.
      }
    }
    offset += subscriptions.length;
    if (subscriptions.length < 50) break;
  }
  return scanned;
}

async function applyPreapproval(client: any, remote: Record<string, unknown>) {
  const id = String(remote.id ?? "");
  if (!id) return "ignored";
  const { data: subscription, error: subscriptionError } = await client.from("subscriptions").select("*")
    .eq("mercadopago_preapproval_id", id).maybeSingle();
  if (subscriptionError) throw subscriptionError;
  if (!subscription) return "ignored";
  const providerStatus = String(remote.status ?? "").toLowerCase();
  const now = new Date();
  const hasPaidPeriod = !!subscription.current_period_end &&
    new Date(subscription.current_period_end).getTime() > now.getTime();

  let patch: Record<string, unknown> = {
    last_reconciled_at: now.toISOString(),
    updated_at: now.toISOString(),
  };
  if (["cancelled", "canceled"].includes(providerStatus)) {
    patch = {
      ...patch,
      status: "cancelled",
      cancelled_at: subscription.cancelled_at ?? now.toISOString(),
      payment_access_status: hasPaidPeriod ? "allowed" : "blocked",
      is_current: hasPaidPeriod,
    };
  } else if (providerStatus === "authorized" &&
    !["active", "payment_pending", "cancelled"].includes(subscription.status)) {
    patch = {
      ...patch,
      status: "waiting_authorization",
      payment_access_status: "blocked",
      // A provider-authorized preapproval is still an open operation even
      // before the first paid invoice arrives.
      is_current: true,
    };
  } else if (["paused", "pending"].includes(providerStatus) && hasPaidPeriod) {
    patch = {
      ...patch,
      status: "payment_pending",
      payment_access_status: "warning_pending",
      is_current: true,
    };
  }
  const { error } = await client.from("subscriptions").update(patch).eq("id", subscription.id);
  if (error) throw error;
  return "processed";
}

async function applyCharge(client: any, charge: CanonicalCharge) {
  const { data: subscription, error: subscriptionError } = await client.from("subscriptions").select("*")
    .eq("mercadopago_preapproval_id", charge.preapprovalId).maybeSingle();
  if (subscriptionError) throw subscriptionError;
  if (!subscription) return "ignored";
  const expectedCents = Number(subscription.value_cents);
  if (charge.status === "approved" &&
    (charge.currency !== "BRL" || charge.amountCents !== expectedCents)) {
    await audit(client, subscription, subscription.status, "blocked", "Cobrança divergente ignorada.", {
      payment_id: charge.paymentId,
      expected_cents: expectedCents,
      received_cents: charge.amountCents,
      currency: charge.currency,
    });
    return "ignored";
  }

  const eventAt = charge.paidAt ? new Date(charge.paidAt) : new Date();
  if (charge.status !== "approved" && subscription.current_period_start &&
    eventAt.getTime() < new Date(subscription.current_period_start).getTime()) {
    return "ignored";
  }
  const state = accessStateForCharge({
    chargeStatus: charge.status,
    currentStatus: subscription.status,
    currentPeriodEnd: subscription.current_period_end,
  });
  if (charge.status !== "approved") {
    const { error: stateError } = await client.from("subscriptions").update({
      status: state.status,
      payment_access_status: state.access,
      is_current: state.status === "waiting_authorization" ||
        state.access !== "blocked",
      last_reconciled_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }).eq("id", subscription.id);
    if (stateError) throw stateError;
    await audit(client, subscription, state.status, state.access, "Cobrança não aprovada.", {
      payment_id: charge.paymentId,
      provider_status: charge.status,
    });
    return "processed";
  }

  const periodStart = eventAt;
  const periodEnd = addUtcMonth(periodStart);
  const currentEnd = subscription.current_period_end
    ? new Date(subscription.current_period_end)
    : null;
  const effectivePeriodEnd = currentEnd && currentEnd.getTime() > periodEnd.getTime()
    ? currentEnd
    : periodEnd;
  const { error: paymentError } = await client.from("mercadopago_authorized_payments").upsert({
    subscription_id: subscription.id,
    user_id: subscription.user_id,
    provider_payment_id: charge.paymentId,
    provider_authorized_payment_id: charge.authorizedPaymentId ?? null,
    preapproval_id: charge.preapprovalId,
    status: charge.status,
    amount_cents: charge.amountCents,
    currency: charge.currency,
    paid_at: periodStart.toISOString(),
    period_start: periodStart.toISOString(),
    period_end: periodEnd.toISOString(),
    raw_resource: charge.raw,
    updated_at: new Date().toISOString(),
  }, { onConflict: "provider_payment_id" });
  if (paymentError) throw paymentError;

  // Store every provider payment for idempotency, but never let an older
  // approved notification move the paid period backwards.
  if (!isNewerPaidPeriod(subscription.current_period_start, periodStart)) {
    return "ignored";
  }

  const cancelled = subscription.status === "cancelled";
  const { error: stateError } = await client.from("subscriptions").update({
    status: cancelled ? "cancelled" : "active",
    payment_access_status: "allowed",
    is_current: true,
    current_period_start: periodStart.toISOString(),
    current_period_end: effectivePeriodEnd.toISOString(),
    next_billing_date: effectivePeriodEnd.toISOString().slice(0, 10),
    authorized_at: subscription.authorized_at ?? periodStart.toISOString(),
    last_reconciled_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  }).eq("id", subscription.id);
  if (stateError) throw stateError;
  await audit(
    client,
    subscription,
    cancelled ? "cancelled" : "active",
    "allowed",
    "Cobrança Mercado Pago aprovada e conciliada.",
    { payment_id: charge.paymentId, period_end: effectivePeriodEnd.toISOString() },
  );
  return "processed";
}

async function audit(
  client: any,
  subscription: any,
  toStatus: string,
  toAccess: string,
  reason: string,
  metadata: Record<string, unknown>,
) {
  if (subscription.status === toStatus && subscription.payment_access_status === toAccess) return;
  const { error } = await client.from("subscription_access_events").insert({
    subscription_id: subscription.id,
    user_id: subscription.user_id,
    from_status: subscription.status,
    to_status: toStatus,
    from_access_status: subscription.payment_access_status,
    to_access_status: toAccess,
    reason,
    source: "mercadopago_reconciliation",
    metadata,
  });
  if (error) throw error;
}

async function processPriceChanges(client: any, mercadoPago: MercadoPagoClient): Promise<number> {
  const { data: items, error: itemsError } = await client.from("mercadopago_price_change_items")
    .select("*,mercadopago_price_change_jobs!inner(new_amount_cents,status)")
    .in("status", ["pending", "failed"])
    .in("mercadopago_price_change_jobs.status", ["pending", "processing"])
    .order("created_at", { ascending: true })
    .limit(25);
  if (itemsError) throw itemsError;
  let processed = 0;
  const jobIds = new Set<string>();
  for (const item of items ?? []) {
    jobIds.add(item.job_id);
    const { error: claimError } = await client.from("mercadopago_price_change_items").update({
      status: "processing",
      attempt_count: Number(item.attempt_count ?? 0) + 1,
      updated_at: new Date().toISOString(),
    }).eq("id", item.id).eq("status", item.status);
    if (claimError) throw claimError;
    try {
      const cents = Number(item.mercadopago_price_change_jobs.new_amount_cents);
      await mercadoPago.updatePreapproval(item.preapproval_id, {
        auto_recurring: { transaction_amount: cents / 100, currency_id: "BRL" },
      });
      const { error: successError } = await client.from("mercadopago_price_change_items").update({
        status: "succeeded",
        last_error: null,
        processed_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }).eq("id", item.id).eq("status", "processing");
      if (successError) throw successError;
      const { error: subscriptionError } = await client.from("subscriptions").update({ value_cents: cents, updated_at: new Date().toISOString() })
        .eq("id", item.subscription_id);
      if (subscriptionError) throw subscriptionError;
      processed++;
    } catch (_) {
      await client.from("mercadopago_price_change_items").update({
        status: "failed",
        last_error: "Falha temporária ao atualizar a assinatura no provedor.",
        updated_at: new Date().toISOString(),
      }).eq("id", item.id);
    }
  }
  for (const jobId of jobIds) {
    const { count: remaining, error: remainingError } = await client.from("mercadopago_price_change_items")
      .select("id", { count: "exact", head: true })
      .eq("job_id", jobId).neq("status", "succeeded");
    if (remainingError) throw remainingError;
    if ((remaining ?? 0) === 0) {
      const { error: jobError } = await client.from("mercadopago_price_change_jobs").update({
        status: "completed",
        completed_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }).eq("id", jobId).in("status", ["pending", "processing"]);
      if (jobError) throw jobError;
    }
  }
  return processed;
}

async function blockExpiredPeriods(client: any): Promise<number> {
  const now = new Date().toISOString();
  const { data: overdue, error } = await client.from("subscriptions")
    .select("id,status")
    .eq("payment_provider", "mercado_pago")
    .eq("is_current", true)
    .in("status", ["active", "payment_pending", "cancelled"])
    .or(`current_period_end.lt.${now},current_period_end.is.null`);
  if (error) throw error;
  for (const row of overdue ?? []) {
    const { error: updateError } = await client.from("subscriptions").update({
      status: row.status === "cancelled" ? "cancelled" : "blocked",
      payment_access_status: "blocked",
      is_current: false,
      blocked_at: row.status === "cancelled" ? null : now,
      updated_at: now,
    }).eq("id", row.id).eq("is_current", true);
    if (updateError) throw updateError;
  }
  return overdue?.length ?? 0;
}
