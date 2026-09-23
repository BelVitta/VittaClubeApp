import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { enforceRateLimit, errorResponse, jsonResponse } from "../_shared/http.ts";
import { hasBillingAdminRole } from "../_shared/mercadopago/auth.ts";
import { MercadoPagoClient } from "../_shared/mercadopago/client.ts";
import { getMercadoPagoEnv } from "../_shared/mercadopago/env.ts";
import {
  accessStateForCharge,
  addUtcMonth,
  isNewerPaidPeriod,
  normalizeCanonicalCharge,
} from "../_shared/mercadopago/state.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return errorResponse("Method not allowed", 405);
  const authHeader = request.headers.get("Authorization");
  if (!authHeader) return errorResponse("Não autenticado.", 401);
  let body: { subscriptionId?: string };
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
  const client = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: auth, error: authError } = await userClient.auth.getUser();
  if (authError || !auth.user) return errorResponse("Não autenticado.", 401);
  const limited = await enforceRateLimit(userClient, "reconcile_mercadopago_subscription", 10);
  if (limited) return limited;
  const { data: subscription } = await client.from("subscriptions").select("*")
    .eq("id", body.subscriptionId).maybeSingle();
  if (!subscription) return errorResponse("Assinatura não encontrada.", 404);
  const admin = await hasBillingAdminRole(userClient, auth.user.id);
  if (subscription.user_id !== auth.user.id && !admin) return errorResponse("Sem permissão.", 403);
  if (!subscription.mercadopago_preapproval_id) return errorResponse("Assinatura sem vínculo externo.", 409);

  try {
    const mercadoPago = new MercadoPagoClient(getMercadoPagoEnv());
    const remote = await mercadoPago.getPreapproval(subscription.mercadopago_preapproval_id);
    const charges = [] as ReturnType<typeof normalizeCanonicalCharge>[];
    let offset = 0;
    while (offset < 1000) {
      const search = await mercadoPago.searchAuthorizedPayments(
        subscription.mercadopago_preapproval_id,
        offset,
      );
      const results = Array.isArray(search.results)
        ? search.results as Record<string, unknown>[]
        : [];
      charges.push(...results
        .map((item) => normalizeCanonicalCharge(item, String(item.id ?? "")))
        .filter((item) => item != null));
      offset += results.length;
      const total = Number((search.paging as Record<string, unknown> | undefined)?.total ?? 0);
      if (results.length < 20 || (total > 0 && offset >= total)) break;
    }
    const approved = charges
      .filter((charge) => charge?.status === "approved")
      .sort((a, b) => String(a!.paidAt ?? "").localeCompare(String(b!.paidAt ?? "")))
      .at(-1);
    const now = new Date();
    let status = subscription.status;
    let access = subscription.payment_access_status;
    let periodStart = subscription.current_period_start;
    let periodEnd = subscription.current_period_end;
    const approvedMatchesPlan = approved != null && approved.currency === "BRL" &&
      approved.amountCents === Number(subscription.value_cents);
    if (approved && !approvedMatchesPlan) {
      const mapped = accessStateForCharge({
        chargeStatus: "rejected",
        currentStatus: status,
        currentPeriodEnd: periodEnd,
        now,
      });
      status = mapped.status;
      access = mapped.access;
    } else if (approved && approvedMatchesPlan) {
      const paidAt = approved.paidAt ? new Date(approved.paidAt) : now;
      const end = addUtcMonth(paidAt);
      const shouldAdvance = isNewerPaidPeriod(subscription.current_period_start, paidAt);
      const paidAtIso = paidAt.toISOString();
      if (shouldAdvance) {
        periodStart = paidAtIso;
        periodEnd = periodEnd && new Date(periodEnd).getTime() > end.getTime()
          ? periodEnd
          : end.toISOString();
        status = subscription.status === "cancelled" ? "cancelled" : "active";
        access = "allowed";
      }
      const { error: paymentError } = await client.from("mercadopago_authorized_payments").upsert({
        subscription_id: subscription.id,
        user_id: subscription.user_id,
        provider_payment_id: approved.paymentId,
        provider_authorized_payment_id: approved.authorizedPaymentId ?? null,
        preapproval_id: approved.preapprovalId,
        status: approved.status,
        amount_cents: approved.amountCents,
        currency: approved.currency,
        paid_at: paidAtIso,
        period_start: paidAtIso,
        period_end: end.toISOString(),
        raw_resource: approved.raw,
        updated_at: now.toISOString(),
      }, { onConflict: "provider_payment_id" });
      if (paymentError) throw paymentError;
    } else if (["cancelled", "canceled"].includes(String(remote.status).toLowerCase())) {
      status = "cancelled";
      access = periodEnd && new Date(periodEnd).getTime() >= now.getTime() ? "allowed" : "blocked";
    } else if (charges.length > 0) {
      const latest = [...charges]
        .sort((a, b) => String(a?.paidAt ?? "").localeCompare(String(b?.paidAt ?? "")))
        .at(-1);
      const mapped = accessStateForCharge({
        chargeStatus: latest!.status,
        currentStatus: status,
        currentPeriodEnd: periodEnd,
      });
      status = mapped.status;
      access = mapped.access;
    }
    const { error: stateError } = await client.from("subscriptions").update({
      status,
      payment_access_status: access,
      current_period_start: periodStart,
      current_period_end: periodEnd,
      next_billing_date: remote.next_payment_date ?? (periodEnd ? String(periodEnd).slice(0, 10) : null),
      // Keep a paid-period cancellation/current pending state visible, but
      // remove blocked/rejected records from the current-subscription slot.
      is_current: status === "waiting_authorization" || access !== "blocked",
      last_reconciled_at: now.toISOString(),
      updated_at: now.toISOString(),
    }).eq("id", subscription.id);
    if (stateError) throw stateError;
    return jsonResponse({ subscriptionId: subscription.id, status, accessUntil: periodEnd });
  } catch (_) {
    return errorResponse("Não foi possível consultar o Mercado Pago agora.", 502);
  }
});
