import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { signPayload, verifyWooviHmac } from "../_shared/woovi/hmac.ts";

Deno.test("validates matching HMAC signature", async () => {
  const payload = JSON.stringify({ event: "OPENPIX:CHARGE_COMPLETED" });
  const signature = await signPayload(payload, "secret");

  assert(await verifyWooviHmac(payload, signature, "secret"));
  assert(await verifyWooviHmac(payload, `sha256=${signature}`, "secret"));
});

Deno.test("rejects invalid HMAC signature", async () => {
  const payload = JSON.stringify({ event: "OPENPIX:CHARGE_COMPLETED" });
  const signature = await signPayload(payload, "secret");

  assertEquals(await verifyWooviHmac(payload, signature, "other-secret"), false);
});
