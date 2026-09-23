export interface MercadoPagoEnv {
  accessToken: string;
  webhookSecret: string;
  returnUrl: string;
  apiBaseUrl: string;
}

export function getMercadoPagoEnv(): MercadoPagoEnv {
  const accessToken = Deno.env.get("MERCADOPAGO_ACCESS_TOKEN") ?? "";
  const webhookSecret = Deno.env.get("MERCADOPAGO_WEBHOOK_SECRET") ?? "";
  const returnUrl = Deno.env.get("MERCADOPAGO_RETURN_URL") ?? "";
  const apiBaseUrl = Deno.env.get("MERCADOPAGO_API_URL") ??
    "https://api.mercadopago.com";

  if (!accessToken) throw new Error("MERCADOPAGO_ACCESS_TOKEN não configurado.");
  if (!returnUrl) throw new Error("MERCADOPAGO_RETURN_URL não configurado.");

  return { accessToken, webhookSecret, returnUrl, apiBaseUrl };
}

