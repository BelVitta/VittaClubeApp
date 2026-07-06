import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { normalizeWooviEvent } from "../_shared/woovi/event_mapper.ts";

Deno.test("uses eventId when provided", async () => {
  const event = await normalizeWooviEvent({
    eventId: "evt-provided",
    event: "OPENPIX:SUBSCRIPTION_CREATED",
  });

  assertEquals(event.eventId, "evt-provided");
});

Deno.test("creates deterministic hash fallback when eventId is absent", async () => {
  const payload = { event: "OPENPIX:SUBSCRIPTION_CREATED" };
  const first = await normalizeWooviEvent(payload);
  const second = await normalizeWooviEvent(payload);

  assert(first.eventId.length > 20);
  assertEquals(first.eventId, second.eventId);
});
