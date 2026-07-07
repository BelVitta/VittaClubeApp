import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { errorResponse, jsonResponse } from "../_shared/http.ts";

const INFINITYPAY_BASE_URL = Deno.env.get("INFINITYPAY_CHECKOUT_API_URL") ??
  "https://api.checkout.infinitepay.io";

interface PaymentIntent {
  id: string;
  user_id: string;
  plan_id: string;
  subscription_id?: string | null;
  order_nsu: string;
  amount: number;
  amount_cents: number;
  status: string;
}

interface InfinityPayPaymentCheck {
  success?: boolean;
  paid?: boolean;
  amount?: number;
  paid_amount?: number;
  installments?: number;
  capture_method?: string;
  receipt_url?: string;
  transaction_nsu?: string;
  order_nsu?: string;
  slug?: string;
  invoice_slug?: string;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  let payload: Record<string, unknown>;
  try {
    payload = await request.json();
  } catch (_) {
    return errorResponse("Payload invalido.", 400);
  }

  const orderNsu = firstString(
    payload.order_nsu,
    nested(payload, "data", "order_nsu"),
    nested(payload, "invoice", "order_nsu"),
    nested(payload, "payment", "order_nsu"),
  );
  const transactionNsu = firstString(
    payload.transaction_nsu,
    nested(payload, "data", "transaction_nsu"),
    nested(payload, "invoice", "transaction_nsu"),
    nested(payload, "payment", "transaction_nsu"),
  );
  const slug = firstString(
    payload.slug,
    payload.invoice_slug,
    nested(payload, "data", "slug"),
    nested(payload, "data", "invoice_slug"),
    nested(payload, "invoice", "slug"),
    nested(payload, "invoice", "invoice_slug"),
    nested(payload, "payment", "slug"),
  );

  if (!orderNsu || !transactionNsu || !slug) {
    return errorResponse(
      "Payload sem order_nsu, transaction_nsu ou slug.",
      400,
    );
  }

  const eventId = `${orderNsu}:${transactionNsu}:${slug}`;
  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { error: eventInsertError } = await serviceClient
    .from("infinitypay_webhook_events")
    .insert({
      event_id: eventId,
      order_nsu: orderNsu,
      transaction_nsu: transactionNsu,
      slug,
      processing_status: "received",
      payload,
    });

  if (eventInsertError?.code === "23505") {
    return jsonResponse({ ok: true, deduplicated: true, eventId });
  }

  if (eventInsertError) {
    return errorResponse(`Erro ao registrar webhook: ${eventInsertError.message}`, 500);
  }

  try {
    const result = await processInfinityPayWebhook(
      serviceClient,
      payload,
      orderNsu,
      transactionNsu,
      slug,
    );

    await serviceClient
      .from("infinitypay_webhook_events")
      .update({
        processing_status: "processed",
        processed_at: new Date().toISOString(),
      })
      .eq("event_id", eventId);

    return jsonResponse({ ok: true, deduplicated: false, eventId, ...result });
  } catch (error) {
    await serviceClient
      .from("infinitypay_webhook_events")
      .update({
        processing_status: "failed",
        processing_error: String(error),
        processed_at: new Date().toISOString(),
      })
      .eq("event_id", eventId);

    return errorResponse(`Erro ao processar webhook: ${String(error)}`, 500);
  }
});

async function processInfinityPayWebhook(
  client: any,
  payload: Record<string, unknown>,
  orderNsu: string,
  transactionNsu: string,
  slug: string,
) {
  const { data: intent, error: intentError } = await client
    .from("payment_intents")
    .select("*")
    .eq("provider", "infinitypay")
    .eq("order_nsu", orderNsu)
    .maybeSingle();

  if (intentError) {
    throw new Error(`Erro ao consultar intencao de pagamento: ${intentError.message}`);
  }

  if (!intent) {
    throw new Error(`Intencao de pagamento nao encontrada para order_nsu ${orderNsu}`);
  }

  const paymentIntent = intent as PaymentIntent;
  const paymentCheck = await checkPayment(orderNsu, transactionNsu, slug);

  if (!paymentCheck.success || !paymentCheck.paid) {
    await client
      .from("payment_intents")
      .update({
        status: "failed",
        transaction_nsu: transactionNsu,
        slug,
        raw_latest_event: payload,
        updated_at: new Date().toISOString(),
      })
      .eq("id", paymentIntent.id);

    return { paid: false, intentId: paymentIntent.id };
  }

  if (paymentIntent.status === "paid" && paymentIntent.subscription_id) {
    return {
      paid: true,
      intentId: paymentIntent.id,
      subscriptionId: paymentIntent.subscription_id,
      idempotent: true,
    };
  }

  const now = new Date();
  const periodEnd = await resolvePeriodEnd(client, paymentIntent.plan_id, now);

  await client
    .from("subscriptions")
    .update({
      is_current: false,
      updated_at: now.toISOString(),
    })
    .eq("user_id", paymentIntent.user_id)
    .eq("is_current", true);

  const { data: subscription, error: subscriptionError } = await client
    .from("subscriptions")
    .insert({
      user_id: paymentIntent.user_id,
      plan_id: paymentIntent.plan_id,
      badge_level: "bronze",
      plan_level_status: "bronze",
      is_current: true,
      status: "active",
      payment_access_status: "allowed",
      activation_date: now.toISOString(),
      current_period_start: now.toISOString(),
      current_period_end: periodEnd.toISOString(),
      next_billing_date: periodEnd.toISOString().slice(0, 10),
      value_cents: paymentIntent.amount_cents,
      currency: "BRL",
      metadata: {
        provider: "infinitypay",
        order_nsu: orderNsu,
        transaction_nsu: paymentCheck.transaction_nsu ?? transactionNsu,
        slug: paymentCheck.slug ?? paymentCheck.invoice_slug ?? slug,
        receipt_url: paymentCheck.receipt_url,
        capture_method: paymentCheck.capture_method,
      },
    })
    .select("id")
    .single();

  if (subscriptionError) {
    throw new Error(`Erro ao ativar assinatura: ${subscriptionError.message}`);
  }

  const subscriptionId = subscription.id as string;
  const captureMethod = paymentCheck.capture_method ??
    firstString(
      payload.capture_method,
      nested(payload, "data", "capture_method"),
      nested(payload, "invoice", "capture_method"),
    );
  const receiptNumber = paymentCheck.transaction_nsu ??
    transactionNsu ??
    paymentCheck.receipt_url ??
    orderNsu;

  const { error: paymentError } = await client
    .from("payments")
    .upsert({
      user_id: paymentIntent.user_id,
      subscription_id: subscriptionId,
      amount: paymentIntent.amount,
      method: paymentMethodDbValue(captureMethod),
      status: "aprovado",
      receipt_number: receiptNumber,
      paid_at: now.toISOString(),
      updated_at: now.toISOString(),
    }, { onConflict: "receipt_number" });

  if (paymentError) {
    throw new Error(`Erro ao registrar pagamento: ${paymentError.message}`);
  }

  const { error: updateIntentError } = await client
    .from("payment_intents")
    .update({
      status: "paid",
      subscription_id: subscriptionId,
      transaction_nsu: paymentCheck.transaction_nsu ?? transactionNsu,
      slug: paymentCheck.slug ?? paymentCheck.invoice_slug ?? slug,
      receipt_url: paymentCheck.receipt_url,
      capture_method: captureMethod,
      raw_latest_event: payload,
      paid_at: now.toISOString(),
      updated_at: now.toISOString(),
    })
    .eq("id", paymentIntent.id);

  if (updateIntentError) {
    throw new Error(`Erro ao atualizar intencao: ${updateIntentError.message}`);
  }

  return {
    paid: true,
    intentId: paymentIntent.id,
    subscriptionId,
  };
}

async function checkPayment(
  orderNsu: string,
  transactionNsu: string,
  slug: string,
): Promise<InfinityPayPaymentCheck> {
  const handle = Deno.env.get("INFINITYPAY_HANDLE");
  if (!handle) {
    throw new Error("INFINITYPAY_HANDLE nao configurado na Edge Function.");
  }

  const response = await fetch(`${INFINITYPAY_BASE_URL}/payment_check`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      handle,
      order_nsu: orderNsu,
      transaction_nsu: transactionNsu,
      slug,
    }),
  });

  if (!response.ok) {
    const responseBody = await response.text();
    throw new Error(
      `payment_check falhou (HTTP ${response.status}): ${responseBody}`,
    );
  }

  return await response.json() as InfinityPayPaymentCheck;
}

async function resolvePeriodEnd(client: any, planId: string, start: Date) {
  const { data: plan } = await client
    .from("plans")
    .select("subscription_type")
    .eq("id", planId)
    .maybeSingle();

  switch (plan?.subscription_type) {
    case "anual":
      return addMonths(start, 12);
    case "semestral":
      return addMonths(start, 6);
    case "mensal":
    default:
      return addMonths(start, 1);
  }
}

function addMonths(date: Date, months: number) {
  return new Date(Date.UTC(
    date.getUTCFullYear(),
    date.getUTCMonth() + months,
    date.getUTCDate(),
    date.getUTCHours(),
    date.getUTCMinutes(),
    date.getUTCSeconds(),
    date.getUTCMilliseconds(),
  ));
}

function paymentMethodDbValue(captureMethod?: string) {
  switch (captureMethod) {
    case "pix":
      return "pix";
    case "boleto":
      return "boleto";
    case "credit_card":
    case "debit_card":
    case "apple_pay":
    case "google_pay":
    default:
      return "cartao_credito";
  }
}

function firstString(...values: unknown[]) {
  for (const value of values) {
    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }
  }
  return undefined;
}

function nested(
  object: Record<string, unknown>,
  key: string,
  nestedKey: string,
) {
  const value = object[key];
  if (!value || typeof value !== "object") return undefined;
  return (value as Record<string, unknown>)[nestedKey];
}
