import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  MercadoPagoApiError,
  MercadoPagoClient,
} from "../_shared/mercadopago/client.ts";

const env = {
  accessToken: "backend-token",
  webhookSecret: "webhook-secret",
  returnUrl: "https://example.test/return",
  apiBaseUrl: "https://provider.test",
};

Deno.test("creates associated preapproval with authentication and idempotency", async () => {
  let capturedUrl = "";
  let capturedInit: RequestInit | undefined;
  const client = new MercadoPagoClient(env, (url, init) => {
    capturedUrl = String(url);
    capturedInit = init;
    return Promise.resolve(Response.json({ id: "preapproval-1", status: "authorized" }));
  });

  const result = await client.createPreapproval({
    preapproval_plan_id: "plan-1",
    external_reference: "local-subscription-1",
    payer_email: "member@example.test",
    card_token_id: "one-use-token",
    status: "authorized",
  }, "vittaclube-subscription-local-subscription-1");

  assertEquals(result.id, "preapproval-1");
  assertEquals(capturedUrl, "https://provider.test/preapproval");
  const headers = new Headers(capturedInit?.headers);
  assertEquals(headers.get("Authorization"), "Bearer backend-token");
  assertEquals(
    headers.get("X-Idempotency-Key"),
    "vittaclube-subscription-local-subscription-1",
  );
});

Deno.test("surfaces canonical provider errors without exposing request data", async () => {
  const client = new MercadoPagoClient(env, () => Promise.resolve(new Response(
    JSON.stringify({ error: "bad_request", message: "invalid card token" }),
    { status: 400, headers: { "content-type": "application/json" } },
  )));

  const error = await assertRejects(
    () => client.createPreapproval({}, "stable-key"),
    MercadoPagoApiError,
  );
  assertEquals(error.status, 400);
  assertEquals(error.code, "bad_request");
});
