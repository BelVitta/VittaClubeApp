interface MercadoPagoSignatureParts {
  ts: string;
  v1: string;
}

export function parseMercadoPagoSignature(
  header: string | null,
): MercadoPagoSignatureParts | null {
  if (!header) return null;
  const parts = Object.fromEntries(
    header.split(",").map((part) => {
      const [key, ...value] = part.trim().split("=");
      return [key, value.join("=")];
    }),
  );
  if (!parts.ts || !parts.v1) return null;
  return { ts: parts.ts, v1: parts.v1.toLowerCase() };
}

export function mercadoPagoSignatureManifest(
  dataId: string,
  requestId: string,
  ts: string,
): string {
  return `id:${dataId.toLowerCase()};request-id:${requestId};ts:${ts};`;
}

export async function verifyMercadoPagoSignature(input: {
  signatureHeader: string | null;
  requestId: string | null;
  dataId: string;
  secret: string;
  nowMs?: number;
  maxAgeSeconds?: number;
}): Promise<boolean> {
  const parsed = parseMercadoPagoSignature(input.signatureHeader);
  if (!parsed || !input.requestId || !input.dataId || !input.secret) return false;

  const timestamp = Number(parsed.ts);
  if (!Number.isFinite(timestamp)) return false;
  const now = input.nowMs ?? Date.now();
  const timestampMs = timestamp < 10_000_000_000 ? timestamp * 1000 : timestamp;
  const maxAgeMs = (input.maxAgeSeconds ?? 300) * 1000;
  if (Math.abs(now - timestampMs) > maxAgeMs) return false;

  const manifest = mercadoPagoSignatureManifest(
    input.dataId,
    input.requestId,
    parsed.ts,
  );
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(input.secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(manifest),
  );
  const expected = [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
  return constantTimeEqual(expected, parsed.v1);
}

function constantTimeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false;
  let result = 0;
  for (let index = 0; index < left.length; index++) {
    result |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return result === 0;
}

