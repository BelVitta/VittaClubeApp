import { sha256Hex } from "./hmac.ts";

export type CanonicalWooviEventType =
  | "subscription_created"
  | "subscription_authorized"
  | "subscription_rejected"
  | "subscription_cancelled"
  | "charge_created"
  | "charge_try_requested"
  | "charge_try_rejected"
  | "charge_completed"
  | "charge_rejected"
  | "unknown";

export interface CanonicalWooviEvent {
  eventId: string;
  eventType: string;
  processedAs: CanonicalWooviEventType;
  subscriptionCorrelationID?: string;
  chargeCorrelationID?: string;
  subscription?: Record<string, unknown>;
  charge?: Record<string, unknown>;
  raw: Record<string, unknown>;
}

const eventMap: Record<string, CanonicalWooviEventType> = {
  "OPENPIX:SUBSCRIPTION_CREATED": "subscription_created",
  "OPENPIX:SUBSCRIPTION_AUTHORIZED": "subscription_authorized",
  "OPENPIX:SUBSCRIPTION_REJECTED": "subscription_rejected",
  "OPENPIX:SUBSCRIPTION_CANCELLED": "subscription_cancelled",
  "OPENPIX:CHARGE_CREATED": "charge_created",
  "OPENPIX:CHARGE_COMPLETED": "charge_completed",
  "OPENPIX:CHARGE_EXPIRED": "charge_rejected",
  "PIX_AUTOMATIC_APPROVED": "subscription_authorized",
  "PIX_AUTOMATIC_REJECTED": "subscription_rejected",
  "PIX_AUTOMATIC_COBR_CREATED": "charge_created",
  "PIX_AUTOMATIC_COBR_APPROVED": "charge_created",
  "PIX_AUTOMATIC_COBR_REJECTED": "charge_rejected",
  "PIX_AUTOMATIC_COBR_TRY_REJECTED": "charge_try_rejected",
  "PIX_AUTOMATIC_COBR_TRY_REQUESTED": "charge_try_requested",
  "PIX_AUTOMATIC_COBR_COMPLETED": "charge_completed",
};

export const normalizeWooviEvent = async (
  payload: Record<string, unknown>,
): Promise<CanonicalWooviEvent> => {
  const eventType = String(payload.event ?? payload.type ?? "unknown");
  const subscription = (payload.subscription ?? payload.pixAutomatic ?? {}) as
    Record<string, unknown>;
  const charge = (payload.charge ?? payload.cobr ?? payload.pixCharge ?? {}) as
    Record<string, unknown>;
  const chargeSubscription = (charge.subscription ?? {}) as Record<
    string,
    unknown
  >;
  const subscriptionCorrelationID = String(
    subscription.correlationID ??
      subscription.correlationId ??
      chargeSubscription.correlationID ??
      chargeSubscription.correlationId ??
      "",
  ) || undefined;
  const chargeCorrelationID = String(
    charge.correlationID ?? charge.correlationId ?? "",
  ) || undefined;

  return {
    eventId: String(
      payload.eventId ??
        payload.id ??
        await sha256Hex(JSON.stringify(payload)),
    ),
    eventType,
    processedAs: eventMap[eventType] ?? "unknown",
    subscriptionCorrelationID,
    chargeCorrelationID,
    subscription,
    charge,
    raw: payload,
  };
};
