-- Mercado Pago recurring card subscriptions (associated preapproval plan).
-- Sensitive card data is tokenized by the native SDK and never stored here.

alter table public.subscriptions
  add column if not exists payment_provider text not null default 'manual',
  add column if not exists mercadopago_preapproval_id text,
  add column if not exists cancellation_reason_text text;

-- The original two-column UNIQUE also allowed only one historical false row.
-- The partial index is the correct invariant: at most one current row.
alter table public.subscriptions drop constraint if exists uq_user_active_subscription;
create unique index if not exists idx_one_active_subscription
  on public.subscriptions (user_id) where is_current = true;

alter table public.plans
  add column if not exists mercadopago_preapproval_plan_id text;

do $$
begin
  alter table public.subscriptions
    add constraint subscriptions_payment_provider_check
    check (payment_provider in ('mercado_pago', 'woovi', 'infinitypay_legacy', 'manual'));
exception when duplicate_object then null;
end $$;

create unique index if not exists subscriptions_mercadopago_preapproval_id_unique
  on public.subscriptions (mercadopago_preapproval_id)
  where mercadopago_preapproval_id is not null;

create unique index if not exists plans_mercadopago_preapproval_plan_id_unique
  on public.plans (mercadopago_preapproval_plan_id)
  where mercadopago_preapproval_plan_id is not null;

-- The former Pix-only fixed-price constraint prevents safe future price changes.
alter table public.subscriptions
  drop constraint if exists subscriptions_value_cents_fixed_check;

do $$
begin
  alter table public.subscriptions
    add constraint subscriptions_value_cents_positive_check
    check (value_cents > 0);
exception when duplicate_object then null;
end $$;

-- Existing Woovi rows predate payment_provider.
update public.subscriptions
set payment_provider = 'woovi'
where (woovi_subscription_id is not null or correlation_id is not null)
  and payment_provider = 'manual';

update public.subscriptions s
set payment_provider = 'infinitypay_legacy'
from public.payment_intents pi
where pi.subscription_id = s.id
  and pi.provider = 'infinitypay'
  and s.payment_provider = 'manual';

-- One commercial offer: continuous monthly membership at R$ 34.90.
update public.plans
set price = 34.90,
    is_active = true,
    discount_label = null,
    updated_at = now()
where subscription_type = 'mensal';

update public.plans
set is_active = false,
    updated_at = now()
where subscription_type in ('semestral', 'anual');

create table if not exists public.mercadopago_webhook_events (
  id uuid primary key default gen_random_uuid(),
  event_key text not null unique,
  request_id text not null,
  topic text not null,
  action text,
  resource_id text not null,
  signature_valid boolean not null default true,
  processing_status text not null default 'received'
    check (processing_status in ('received', 'processing', 'processed', 'failed', 'ignored')),
  attempt_count integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  processing_error text,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);

create index if not exists mercadopago_webhook_events_pending_idx
  on public.mercadopago_webhook_events (processing_status, next_attempt_at, received_at);

create table if not exists public.mercadopago_authorized_payments (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider_payment_id text not null unique,
  provider_authorized_payment_id text,
  preapproval_id text not null,
  status text not null,
  amount_cents integer not null check (amount_cents > 0),
  currency text not null,
  paid_at timestamptz,
  period_start timestamptz,
  period_end timestamptz,
  raw_resource jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists mercadopago_authorized_payment_resource_unique
  on public.mercadopago_authorized_payments (provider_authorized_payment_id)
  where provider_authorized_payment_id is not null;

create index if not exists mercadopago_authorized_payments_subscription_idx
  on public.mercadopago_authorized_payments (subscription_id, paid_at desc);

create table if not exists public.mercadopago_price_change_jobs (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.plans(id) on delete restrict,
  old_amount_cents integer not null check (old_amount_cents > 0),
  new_amount_cents integer not null check (new_amount_cents > 0),
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'completed', 'completed_with_errors', 'failed')),
  requested_by uuid references public.profiles(id) on delete set null,
  provider_plan_updated_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists mercadopago_one_open_price_job_per_plan
  on public.mercadopago_price_change_jobs (plan_id)
  where status in ('pending', 'processing');

create table if not exists public.mercadopago_price_change_items (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.mercadopago_price_change_jobs(id) on delete cascade,
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  preapproval_id text not null,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'succeeded', 'failed')),
  attempt_count integer not null default 0,
  last_error text,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (job_id, subscription_id)
);

create index if not exists mercadopago_price_change_items_pending_idx
  on public.mercadopago_price_change_items (job_id, status, created_at);

alter table public.mercadopago_webhook_events enable row level security;
alter table public.mercadopago_authorized_payments enable row level security;
alter table public.mercadopago_price_change_jobs enable row level security;
alter table public.mercadopago_price_change_items enable row level security;

drop policy if exists "Users can view own Mercado Pago payments"
  on public.mercadopago_authorized_payments;
create policy "Users can view own Mercado Pago payments"
  on public.mercadopago_authorized_payments for select
  using (auth.uid() = user_id or is_admin() or is_financeiro());

-- Webhooks and price jobs are service-role only. No authenticated write policy is
-- intentionally created; service_role bypasses RLS.

revoke insert, update, delete on public.subscriptions from anon, authenticated;
revoke insert, update, delete on public.mercadopago_authorized_payments from anon, authenticated;
revoke all on public.mercadopago_webhook_events from anon, authenticated;
revoke all on public.mercadopago_price_change_jobs from anon, authenticated;
revoke all on public.mercadopago_price_change_items from anon, authenticated;

-- Cancellation must not revoke a paid period. This also repairs old cancelled
-- records that were made non-current even though access is still valid.
update public.subscriptions
set payment_access_status = 'allowed'
where status = 'cancelled'
  and current_period_end is not null
  and current_period_end >= now();

comment on column public.subscriptions.mercadopago_preapproval_id is
  'Mercado Pago preapproval identifier. Card tokens and PCI data are never persisted.';
comment on table public.mercadopago_webhook_events is
  'Idempotent ingress queue. Payloads are never trusted without canonical API retrieval.';
