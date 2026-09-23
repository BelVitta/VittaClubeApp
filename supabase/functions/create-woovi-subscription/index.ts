import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { enforceRateLimit, errorResponse, jsonResponse } from "../_shared/http.ts";
import { WooviClient } from "../_shared/woovi/client.ts";
import { getWooviEnv } from "../_shared/woovi/env.ts";

interface CreateSubscriptionBody {
  planId?: string;
  customer?: {
    name?: string;
    taxID?: string;
    email?: string;
    phone?: string;
    address?: BillingAddress;
  };
}

interface BillingAddress {
  zipcode?: string;
  street?: string;
  number?: string;
  complement?: string;
  neighborhood?: string;
  city?: string;
  state?: string;
}

const requiredCustomerFields = ["name", "taxID", "email", "phone"] as const;
const requiredAddressFields = [
  "zipcode",
  "street",
  "number",
  "neighborhood",
  "city",
  "state",
] as const;

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  const authHeader = request.headers.get("Authorization");
  if (!authHeader) {
    return errorResponse("Usuário não autenticado.", 401);
  }

  let body: CreateSubscriptionBody;
  try {
    body = await request.json();
  } catch (_) {
    return errorResponse("Payload inválido.", 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const serviceClient = createClient(supabaseUrl, serviceRoleKey);

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return errorResponse("Usuário não autenticado.", 401);
  }

  const limited = await enforceRateLimit(userClient, "create_woovi_subscription", 5);
  if (limited) return limited;

  if (!body.planId) return errorResponse("planId é obrigatório.", 400);

  const { data: plan, error: planError } = await serviceClient
    .from("plans")
    .select("id,subscription_type,price,is_active")
    .eq("id", body.planId)
    .maybeSingle();
  if (planError) return errorResponse("Erro ao consultar o plano.", 500);
  if (!plan || !plan.is_active || plan.subscription_type !== "mensal") {
    return errorResponse("Este plano mensal não está disponível.", 409);
  }
  const valueCents = Math.round(Number(plan.price) * 100);
  if (valueCents !== 3490) {
    return errorResponse("O plano Pix precisa estar configurado em R$34,90.", 409);
  }

  const userId = userData.user.id;
  let customer;
  try {
    customer = await resolveCustomer(serviceClient, userId, body.customer ?? {});
  } catch (error) {
    return errorResponse(String(error), 500);
  }
  const missingCustomerField = requiredCustomerFields.find((field) => !customer[field]);
  if (missingCustomerField) {
    return errorResponse(`Campo obrigatório ausente: customer.${missingCustomerField}`, 400);
  }
  const missingAddressField = requiredAddressFields.find(
    (field) => !customer.address?.[field],
  );
  if (missingAddressField) {
    return errorResponse(`Campo obrigatório ausente: customer.address.${missingAddressField}`, 400);
  }

  const { data: existingRows, error: existingError } = await serviceClient
    .from("subscriptions")
    .select("*")
    .eq("user_id", userId)
    .in("status", ["active", "payment_pending", "waiting_authorization"])
    .order("created_at", { ascending: false })
    .limit(20);

  if (existingError) {
    return errorResponse(`Erro ao consultar assinatura: ${existingError.message}`, 500);
  }

  const existing = (existingRows ?? []).find((row) => {
    const paidUntil = row.current_period_end
      ? new Date(row.current_period_end).getTime()
      : 0;
    return row.status === "waiting_authorization" || paidUntil >= Date.now();
  });
  if (existing) {
    if (existing.status === "waiting_authorization") {
      return jsonResponse({
        subscription: toResponseSubscription(existing),
        ui: waitingUi(existing.payment_link_url),
      });
    }
    return errorResponse("Já existe uma assinatura em andamento ou ativa.", 409);
  }

  const env = getWooviEnv();
  const woovi = new WooviClient(env);
  const now = new Date();
  const dayGenerateCharge = now.getDate();
  const correlationID = `vittaclube-${userId}-${now.getTime()}`;

  let wooviResponse;
  try {
    wooviResponse = await woovi.createSubscription({
      correlationID,
      type: "PIX_RECURRING",
      value: valueCents,
      frequency: env.frequency,
      dayGenerateCharge,
      dayDue: dayGenerateCharge,
      pixRecurringOptions: {
        journey: env.journey,
        retryPolicy: env.retryPolicy,
      },
      customer: {
        name: customer.name!,
        taxID: customer.taxID!,
        email: customer.email!,
        phone: customer.phone!,
        address: normalizeAddress(customer.address!),
      },
      comment: "VittaClube - assinatura mensal recorrente R$34,90",
    });
  } catch (error) {
    return errorResponse(`Erro ao criar assinatura na Woovi: ${String(error)}`, 502);
  }

  const subscription = wooviResponse.subscription ?? wooviResponse;
  const paymentLinkUrl = subscription.paymentLinkUrl as string | undefined;

  const { error: retireError } = await serviceClient
    .from("subscriptions")
    .update({ is_current: false })
    .eq("user_id", userId)
    .eq("is_current", true);
  if (retireError) {
    try {
      await woovi.cancelSubscription(subscription.id ?? subscription.globalID ?? correlationID);
    } catch (_) {
      // The response below remains generic; the remote cancellation is retried
      // by reconciliation if the provider did not accept the compensation.
    }
    return errorResponse("Não foi possível preparar a assinatura local.", 500);
  }

  const { data: inserted, error: insertError } = await serviceClient
    .from("subscriptions")
    .insert({
      user_id: userId,
      plan_id: plan.id,
      badge_level: "bronze",
      plan_level_status: "bronze",
      is_current: true,
      status: "waiting_authorization",
      payment_access_status: "blocked",
      payment_provider: "woovi",
      woovi_subscription_id: subscription.id ?? subscription.globalID ?? null,
      correlation_id: correlationID,
      payment_link_url: paymentLinkUrl,
      value_cents: valueCents,
      interval: env.frequency,
      journey: env.journey,
      retry_policy: env.retryPolicy,
      day_generate_charge: dayGenerateCharge,
      next_billing_date: now.toISOString().slice(0, 10),
      metadata: {
        woovi: subscription,
        customer: {
          name: customer.name,
          taxID: customer.taxID,
          email: customer.email,
          phone: customer.phone,
          address: normalizeAddress(customer.address!),
        },
      },
    })
    .select()
    .single();

  if (insertError) {
    try {
      await woovi.cancelSubscription(subscription.id ?? subscription.globalID ?? correlationID);
    } catch (_) {
      // Keep the original error while reconciliation can detect the orphan.
    }
    return errorResponse(`Erro ao persistir assinatura: ${insertError.message}`, 500);
  }

  return jsonResponse({
    subscription: toResponseSubscription(inserted),
    ui: waitingUi(paymentLinkUrl),
  });
});

async function resolveCustomer(
  serviceClient: any,
  userId: string,
  inputCustomer: NonNullable<CreateSubscriptionBody["customer"]>,
) {
  if (inputCustomer.address) return inputCustomer;

  const { data, error } = await serviceClient
    .from("billing_profiles")
    .select("name,tax_id,email,phone,zipcode,street,number,complement,neighborhood,city,state")
    .eq("user_id", userId)
    .maybeSingle();

  if (error) {
    throw new Error(`Erro ao consultar dados de cobrança: ${error.message}`);
  }

  if (!data) return inputCustomer;

  return {
    name: inputCustomer.name ?? data.name,
    taxID: inputCustomer.taxID ?? data.tax_id,
    email: inputCustomer.email ?? data.email,
    phone: inputCustomer.phone ?? data.phone,
    address: {
      zipcode: data.zipcode,
      street: data.street,
      number: data.number,
      complement: data.complement ?? undefined,
      neighborhood: data.neighborhood,
      city: data.city,
      state: data.state,
    },
  };
}

function normalizeAddress(address: BillingAddress) {
  return {
    zipcode: String(address.zipcode),
    street: String(address.street),
    number: String(address.number),
    ...(address.complement ? { complement: String(address.complement) } : {}),
    neighborhood: String(address.neighborhood),
    city: String(address.city),
    state: String(address.state).toUpperCase(),
  };
}

function toResponseSubscription(row: Record<string, unknown>) {
  return {
    id: row.id,
    correlationID: row.correlation_id,
    value: row.value_cents,
    interval: row.interval,
    status: "WAITING_AUTHORIZATION",
    paymentLinkUrl: row.payment_link_url,
    createdAt: row.created_at,
  };
}

function waitingUi(paymentLinkUrl: unknown) {
  return {
    state: "WAITING_AUTHORIZATION",
    title: "Autorize no app do seu banco",
    message:
      "Você está autorizando uma cobrança recorrente automática de R$34,90 por mês.",
    primaryAction: paymentLinkUrl ? "Abrir banco" : "Aguardar confirmação",
  };
}
