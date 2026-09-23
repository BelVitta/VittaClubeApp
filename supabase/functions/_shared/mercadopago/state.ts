export type MercadoPagoCanonicalKind =
  | "payment"
  | "authorized_payment"
  | "preapproval"
  | "plan"
  | "unknown";

export function canonicalKind(topic: string): MercadoPagoCanonicalKind {
  const normalized = topic.toLowerCase();
  if (normalized === "payment") return "payment";
  if (normalized.includes("authorized_payment")) return "authorized_payment";
  if (normalized.includes("preapproval_plan") || normalized.endsWith("plan")) {
    return "plan";
  }
  if (normalized.includes("preapproval") || normalized.includes("subscription")) {
    return "preapproval";
  }
  return "unknown";
}

export interface CanonicalCharge {
  paymentId: string;
  authorizedPaymentId?: string;
  preapprovalId: string;
  status: string;
  amountCents: number;
  currency: string;
  paidAt?: string;
  raw: Record<string, unknown>;
}

export function normalizeCanonicalCharge(
  resource: Record<string, unknown>,
  authorizedPaymentId?: string,
): CanonicalCharge | null {
  const nestedPayment = asRecord(resource.payment);
  const payment = nestedPayment ?? resource;
  const paymentId = stringValue(payment.id ?? resource.payment_id);
  const preapprovalId = stringValue(
    resource.preapproval_id ??
      resource.subscription_id ??
      asRecord(resource.metadata)?.preapproval_id ??
      asRecord(payment.metadata)?.preapproval_id,
  );
  if (!paymentId || !preapprovalId) return null;

  const amount = numberValue(
    payment.transaction_amount ?? resource.transaction_amount ?? resource.amount,
  );
  return {
    paymentId,
    authorizedPaymentId,
    preapprovalId,
    status: stringValue(payment.status ?? resource.status).toLowerCase(),
    amountCents: Math.round(amount * 100),
    currency: stringValue(payment.currency_id ?? resource.currency_id).toUpperCase(),
    paidAt: optionalString(
      payment.date_approved ?? resource.debit_date ?? resource.date_created,
    ),
    raw: resource,
  };
}

export function accessStateForCharge(input: {
  chargeStatus: string;
  currentStatus: string;
  currentPeriodEnd?: string | null;
  now?: Date;
}): { status: string; access: string } {
  const chargeStatus = input.chargeStatus.toLowerCase();
  if (chargeStatus === "approved") return { status: "active", access: "allowed" };

  const now = input.now ?? new Date();
  const hasPaidPeriod = !!input.currentPeriodEnd &&
    new Date(input.currentPeriodEnd).getTime() > now.getTime();
  if (["pending", "in_process", "in_mediation", "rejected"].includes(chargeStatus)) {
    return hasPaidPeriod
      ? { status: "payment_pending", access: "warning_pending" }
      : { status: input.currentStatus === "waiting_authorization" ? "rejected" : "blocked", access: "blocked" };
  }
  return { status: input.currentStatus, access: hasPaidPeriod ? "allowed" : "blocked" };
}

export function addUtcMonth(date: Date): Date {
  const day = date.getUTCDate();
  const result = new Date(Date.UTC(
    date.getUTCFullYear(),
    date.getUTCMonth() + 1,
    1,
    date.getUTCHours(),
    date.getUTCMinutes(),
    date.getUTCSeconds(),
    date.getUTCMilliseconds(),
  ));
  const lastDay = new Date(Date.UTC(
    result.getUTCFullYear(),
    result.getUTCMonth() + 1,
    0,
  )).getUTCDate();
  result.setUTCDate(Math.min(day, lastDay));
  return result;
}

/**
 * A late webhook may describe an invoice that is older than the period
 * already applied. Only a strictly newer paid timestamp may advance access.
 */
export function isNewerPaidPeriod(
  currentPeriodStart: string | null | undefined,
  candidatePaidAt: Date,
): boolean {
  if (!currentPeriodStart) return true;
  const current = Date.parse(currentPeriodStart);
  return Number.isNaN(current) || candidatePaidAt.getTime() > current;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === "object" ? value as Record<string, unknown> : null;
}

function stringValue(value: unknown): string {
  return value == null ? "" : String(value);
}

function optionalString(value: unknown): string | undefined {
  const result = stringValue(value);
  return result || undefined;
}

function numberValue(value: unknown): number {
  const result = Number(value);
  return Number.isFinite(result) ? result : 0;
}
