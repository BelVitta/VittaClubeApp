export type WooviEnvironmentName = "sandbox" | "production";

export interface WooviEnv {
  baseUrl: string;
  appId: string;
  webhookSecret: string;
  environment: WooviEnvironmentName;
  valueCents: number;
  frequency: "MONTHLY";
  journey: "PAYMENT_ON_APPROVAL";
  retryPolicy: "THREE_RETRIES_7_DAYS";
}

export function getWooviEnv(): WooviEnv {
  const environment = (Deno.env.get("WOOVI_ENVIRONMENT") ?? "sandbox") as
    WooviEnvironmentName;
  const baseUrl = Deno.env.get("WOOVI_BASE_URL") ??
    (environment === "production"
      ? "https://api.woovi.com"
      : "https://api.woovi-sandbox.com");
  const appId = Deno.env.get("WOOVI_APP_ID");
  const webhookSecret = Deno.env.get("WOOVI_WEBHOOK_SECRET");

  if (!appId) {
    throw new Error("WOOVI_APP_ID is required");
  }

  if (!webhookSecret) {
    throw new Error("WOOVI_WEBHOOK_SECRET is required");
  }

  return {
    baseUrl,
    appId,
    webhookSecret,
    environment,
    valueCents: Number(Deno.env.get("VITTACLUBE_SUBSCRIPTION_VALUE_CENTS") ?? 3490),
    frequency: "MONTHLY",
    journey: "PAYMENT_ON_APPROVAL",
    retryPolicy: "THREE_RETRIES_7_DAYS",
  };
}
