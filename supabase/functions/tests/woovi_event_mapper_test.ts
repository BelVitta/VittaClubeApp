import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { normalizeWooviEvent } from "../_shared/woovi/event_mapper.ts";

Deno.test("normalizes Pix Automatic completed charge event", async () => {
  const event = await normalizeWooviEvent({
    eventId: "evt-1",
    event: "PIX_AUTOMATIC_COBR_COMPLETED",
    subscription: { correlationID: "sub-1" },
    charge: { correlationID: "charge-1" },
  });

  assertEquals(event.eventId, "evt-1");
  assertEquals(event.processedAs, "charge_completed");
  assertEquals(event.subscriptionCorrelationID, "sub-1");
  assertEquals(event.chargeCorrelationID, "charge-1");
});

Deno.test("normalizes OpenPix subscription authorized event", async () => {
  const event = await normalizeWooviEvent({
    id: "evt-2",
    event: "OPENPIX:SUBSCRIPTION_AUTHORIZED",
    subscription: { correlationId: "sub-2" },
  });

  assertEquals(event.eventId, "evt-2");
  assertEquals(event.processedAs, "subscription_authorized");
  assertEquals(event.subscriptionCorrelationID, "sub-2");
});
