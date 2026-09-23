import type { MercadoPagoEnv } from "./env.ts";

export class MercadoPagoApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

export class MercadoPagoClient {
  constructor(
    private readonly env: MercadoPagoEnv,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  createPlan(input: Record<string, unknown>, idempotencyKey: string) {
    return this.request("/preapproval_plan", {
      method: "POST",
      body: JSON.stringify(input),
      headers: { "X-Idempotency-Key": idempotencyKey },
    });
  }

  updatePlan(id: string, input: Record<string, unknown>) {
    return this.request(`/preapproval_plan/${encodeURIComponent(id)}`, {
      method: "PUT",
      body: JSON.stringify(input),
    });
  }

  getPlan(id: string) {
    return this.request(`/preapproval_plan/${encodeURIComponent(id)}`);
  }

  createPreapproval(input: Record<string, unknown>, idempotencyKey: string) {
    return this.request("/preapproval", {
      method: "POST",
      body: JSON.stringify(input),
      headers: { "X-Idempotency-Key": idempotencyKey },
    });
  }

  updatePreapproval(id: string, input: Record<string, unknown>) {
    return this.request(`/preapproval/${encodeURIComponent(id)}`, {
      method: "PUT",
      body: JSON.stringify(input),
    });
  }

  getPreapproval(id: string) {
    return this.request(`/preapproval/${encodeURIComponent(id)}`);
  }

  searchPreapproval(externalReference: string) {
    const query = new URLSearchParams({ external_reference: externalReference });
    return this.request(`/preapproval/search?${query.toString()}`);
  }

  getPayment(id: string) {
    return this.request(`/v1/payments/${encodeURIComponent(id)}`);
  }

  getAuthorizedPayment(id: string) {
    return this.request(`/authorized_payments/${encodeURIComponent(id)}`);
  }

  searchAuthorizedPayments(preapprovalId: string, offset = 0) {
    const query = new URLSearchParams({
      preapproval_id: preapprovalId,
      limit: "20",
      offset: String(offset),
    });
    return this.request(`/authorized_payments/search?${query.toString()}`);
  }

  private async request(path: string, init: RequestInit = {}) {
    const response = await this.fetcher(`${this.env.apiBaseUrl}${path}`, {
      ...init,
      headers: {
        Authorization: `Bearer ${this.env.accessToken}`,
        "Content-Type": "application/json",
        Accept: "application/json",
        ...(init.headers ?? {}),
      },
    });

    const text = await response.text();
    let data: Record<string, unknown> = {};
    if (text) {
      try {
        data = JSON.parse(text);
      } catch (_) {
        data = { message: "Resposta inválida do provedor." };
      }
    }

    if (!response.ok) {
      const code = String(data.error ?? data.code ?? "provider_error");
      const message = String(data.message ?? "Falha na API do Mercado Pago.");
      throw new MercadoPagoApiError(response.status, code, message);
    }
    return data;
  }
}
