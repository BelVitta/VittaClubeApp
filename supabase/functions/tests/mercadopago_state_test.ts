import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  accessStateForCharge,
  canonicalKind,
  isNewerPaidPeriod,
  normalizeCanonicalCharge,
} from "../_shared/mercadopago/state.ts";

Deno.test("maps supported webhook topics to canonical resources", () => {
  assertEquals(canonicalKind("payment"), "payment");
  assertEquals(canonicalKind("subscription_authorized_payment"), "authorized_payment");
  assertEquals(canonicalKind("subscription_preapproval"), "preapproval");
  assertEquals(canonicalKind("subscription_preapproval_plan"), "plan");
});

Deno.test("does not move a paid period backwards when webhooks arrive late", () => {
  assertEquals(
    isNewerPaidPeriod("2026-09-20T12:00:00Z", new Date("2026-09-19T12:00:00Z")),
    false,
  );
  assertEquals(
    isNewerPaidPeriod("2026-09-20T12:00:00Z", new Date("2026-09-21T12:00:00Z")),
    true,
  );
});

Deno.test("normalizes approved authorized payment without trusting webhook fields", () => {
  const charge = normalizeCanonicalCharge({
    id: "auth-1",
    preapproval_id: "preapproval-1",
    payment: {
      id: 99,
      status: "approved",
      transaction_amount: 34.90,
      currency_id: "BRL",
      date_approved: "2026-09-17T12:00:00Z",
    },
  }, "auth-1");
  assertEquals(charge?.paymentId, "99");
  assertEquals(charge?.amountCents, 3490);
  assertEquals(charge?.currency, "BRL");
});

Deno.test("approved activates; rejection preserves only an existing paid period", () => {
  assertEquals(accessStateForCharge({
    chargeStatus: "approved",
    currentStatus: "waiting_authorization",
  }), { status: "active", access: "allowed" });
  assertEquals(accessStateForCharge({
    chargeStatus: "rejected",
    currentStatus: "active",
    currentPeriodEnd: "2026-10-17T00:00:00Z",
    now: new Date("2026-09-17T00:00:00Z"),
  }), { status: "payment_pending", access: "warning_pending" });
  assertEquals(accessStateForCharge({
    chargeStatus: "rejected",
    currentStatus: "waiting_authorization",
    now: new Date("2026-09-17T00:00:00Z"),
  }), { status: "rejected", access: "blocked" });
  assertEquals(accessStateForCharge({
    chargeStatus: "rejected",
    currentStatus: "active",
    currentPeriodEnd: "2026-09-17T00:00:00Z",
    now: new Date("2026-09-17T00:00:00Z"),
  }), { status: "blocked", access: "blocked" });
});
