const encoder = new TextEncoder();

export async function sha256Hex(value: string): Promise<string> {
  const data = encoder.encode(value);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(hash)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export async function signPayload(
  payload: string,
  secret: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(payload));
  return [...new Uint8Array(signature)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i += 1) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}

export function normalizeSignature(signature: string | null): string {
  if (!signature) return "";
  const match = signature.match(/sha256=([a-fA-F0-9]+)/);
  return (match?.[1] ?? signature).trim().toLowerCase();
}

export async function verifyWooviHmac(
  payload: string,
  signature: string | null,
  secret: string,
): Promise<boolean> {
  const expected = await signPayload(payload, secret);
  return timingSafeEqual(expected, normalizeSignature(signature));
}
