import { WooviEnv } from "./env.ts";

export interface WooviCustomer {
  name: string;
  taxID: string;
  email: string;
  phone: string;
  address: {
    zipcode: string;
    street: string;
    number: string;
    complement?: string;
    neighborhood: string;
    city: string;
    state: string;
  };
}

export interface CreateWooviSubscriptionInput {
  type: "PIX_RECURRING";
  correlationID: string;
  value: number;
  frequency: "MONTHLY";
  dayGenerateCharge: number;
  dayDue: number;
  pixRecurringOptions: {
    journey: "PAYMENT_ON_APPROVAL";
    retryPolicy: "THREE_RETRIES_7_DAYS";
  };
  customer: WooviCustomer;
  comment?: string;
}

export class WooviClient {
  private env: WooviEnv;

  constructor(env: WooviEnv) {
    this.env = env;
  }

  async createSubscription(input: CreateWooviSubscriptionInput) {
    return this.request("/api/v1/subscriptions", {
      method: "POST",
      body: JSON.stringify(input),
    });
  }

  async getSubscription(idOrCorrelationID: string) {
    return this.request(`/api/v1/subscriptions/${encodeURIComponent(idOrCorrelationID)}`, {
      method: "GET",
    });
  }

  async cancelSubscription(idOrCorrelationID: string) {
    return this.request(`/api/v1/subscriptions/${encodeURIComponent(idOrCorrelationID)}`, {
      method: "DELETE",
    });
  }

  private async request(path: string, init: RequestInit) {
    const response = await fetch(`${this.env.baseUrl}${path}`, {
      ...init,
      headers: {
        "Authorization": this.env.appId,
        "Content-Type": "application/json",
        ...(init.headers ?? {}),
      },
    });

    const text = await response.text();
    const data = text ? JSON.parse(text) : null;

    if (!response.ok) {
      throw new Error(
        `Woovi request failed ${response.status}: ${JSON.stringify(data)}`,
      );
    }

    return data;
  }
}
