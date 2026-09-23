import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  mercadoPagoSignatureManifest,
  verifyMercadoPagoSignature,
} from "../_shared/mercadopago/webhook_signature.ts";

async function hmac(value: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

Deno.test("validates Mercado Pago x-signature manifest and freshness", async () => {
  const now = 1_700_000_000_000;
  const ts = String(now / 1000);
  const digest = await hmac(
    mercadoPagoSignatureManifest("ABC-123", "request-1", ts),
    "webhook-secret",
  );
  assert(await verifyMercadoPagoSignature({
    signatureHeader: `ts=${ts},v1=${digest}`,
    requestId: "request-1",
    dataId: "ABC-123",
    secret: "webhook-secret",
    nowMs: now,
  }));
});

Deno.test("rejects invalid or stale Mercado Pago signatures", async () => {
  assertEquals(await verifyMercadoPagoSignature({
    signatureHeader: "ts=100,v1=deadbeef",
    requestId: "request-1",
    dataId: "1",
    secret: "secret",
    nowMs: 1_700_000_000_000,
  }), false);
});

