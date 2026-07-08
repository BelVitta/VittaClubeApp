-- Pix Automatic subscription support for VittaClube.

do $$
begin
  create type public.subscription_status as enum (
    'none',
    'waiting_authorization',
    'active',
    'payment_pending',
    'blocked',
    'rejected',
    'cancelled',
    'expired'
  );
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.payment_access_status as enum (
    'allowed',
    'warning_pending',
    'blocked'
  );
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.subscription_charge_status as enum (
    'created',
    'scheduled',
    'paid',
    'failed',
    'retrying',
    'expired',
    'cancelled'
  );
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.subscription_charge_attempt_status as enum (
    'requested',
    'approved',
    'rejected',
    'completed',
    'failed'
  );
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.subscription_refund_status as enum (
    'requested',
    'approved',
    'rejected',
    'refunded',
    'cancelled'
  );
exception
  when duplicate_object then null;
end $$;

create table if not exists public.billing_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  tax_id text not null,
  email text not null,
  phone text not null,
  zipcode text not null,
  street text not null,
  number text not null,
  complement text,
  neighborhood text not null,
  city text not null,
  state text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint billing_profiles_tax_id_check check (tax_id ~ '^\d{11}$'),
  constraint billing_profiles_zipcode_check check (zipcode ~ '^\d{8}$'),
  constraint billing_profiles_state_check check (state ~ '^[A-Z]{2}$')
);

alter table public.billing_profiles enable row level security;

drop policy if exists "Users can view own billing profile" on public.billing_profiles;
create policy "Users can view own billing profile"
  on public.billing_profiles for select
  using (auth.uid() = user_id);

drop policy if exists "Users can upsert own billing profile" on public.billing_profiles;
create policy "Users can upsert own billing profile"
  on public.billing_profiles for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own billing profile" on public.billing_profiles;
create policy "Users can update own billing profile"
  on public.billing_profiles for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

alter table public.subscriptions
  add column if not exists status public.subscription_status not null default 'none',
  add column if not exists payment_access_status public.payment_access_status not null default 'blocked',
  add column if not exists woovi_subscription_id text,
  add column if not exists correlation_id text,
  add column if not exists payment_link_url text,
  add column if not exists value_cents integer not null default 3490,
  add column if not exists currency text not null default 'BRL',
  add column if not exists interval text not null default 'MONTHLY',
  add column if not exists journey text not null default 'PAYMENT_ON_APPROVAL',
  add column if not exists retry_policy text not null default 'THREE_RETRIES_7_DAYS',
  add column if not exists day_generate_charge integer,
  add column if not exists current_period_start timestamptz,
  add column if not exists current_period_end timestamptz,
  add column if not exists next_billing_date date,
  add column if not exists authorized_at timestamptz,
  add column if not exists rejected_at timestamptz,
  add column if not exists blocked_at timestamptz,
  add column if not exists last_reconciled_at timestamptz,
  add column if not exists metadata jsonb not null default '{}'::jsonb,
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  alter table public.subscriptions
    add constraint subscriptions_value_cents_fixed_check
    check (value_cents = 3490);
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter table public.subscriptions
    add constraint subscriptions_pix_interval_check
    check (interval = 'MONTHLY');
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter table public.subscriptions
    add constraint subscriptions_pix_journey_check
    check (journey = 'PAYMENT_ON_APPROVAL');
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter table public.subscriptions
    add constraint subscriptions_pix_retry_policy_check
    check (retry_policy = 'THREE_RETRIES_7_DAYS');
exception
  when duplicate_object then null;
end $$;

create unique index if not exists subscriptions_correlation_id_unique
  on public.subscriptions (correlation_id)
  where correlation_id is not null;

create table if not exists public.subscription_charges (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  woovi_charge_id text,
  woovi_cobr_id text,
  correlation_id text not null unique,
  subscription_correlation_id text not null,
  value_cents integer not null default 3490 check (value_cents = 3490),
  status public.subscription_charge_status not null default 'created',
  cycle_reference text not null,
  due_date date,
  paid_at timestamptz,
  failed_at timestamptz,
  recovery_started_at timestamptz,
  recovery_deadline_at timestamptz,
  attempt_count integer not null default 0 check (attempt_count between 0 and 3),
  failure_reason text,
  raw_latest_event jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.subscription_charge_attempts (
  id uuid primary key default gen_random_uuid(),
  subscription_charge_id uuid not null references public.subscription_charges(id) on delete cascade,
  attempt_number integer not null check (attempt_number between 1 and 3),
  status public.subscription_charge_attempt_status not null,
  requested_at timestamptz,
  completed_at timestamptz,
  rejected_at timestamptz,
  failure_reason text,
  woovi_attempt_id text,
  raw_event jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (subscription_charge_id, attempt_number)
);

create table if not exists public.woovi_webhook_events (
  id uuid primary key default gen_random_uuid(),
  event_id text not null unique,
  event_type text not null,
  subscription_correlation_id text,
  charge_correlation_id text,
  signature_valid boolean not null default true,
  processing_status text not null default 'received',
  processing_error text,
  processed_at timestamptz,
  payload jsonb not null,
  received_at timestamptz not null default now()
);

create table if not exists public.subscription_access_events (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid references public.subscriptions(id) on delete set null,
  user_id uuid references auth.users(id) on delete cascade,
  from_status public.subscription_status,
  to_status public.subscription_status,
  from_access_status public.payment_access_status,
  to_access_status public.payment_access_status,
  reason text not null,
  source text not null default 'system',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.subscription_refund_requests (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  charge_id uuid not null references public.subscription_charges(id) on delete cascade,
  status public.subscription_refund_status not null default 'requested',
  reason text,
  admin_note text,
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  refunded_at timestamptz,
  reviewed_by uuid references auth.users(id),
  eligibility_checked_at timestamptz,
  has_benefit_usage boolean not null default false,
  metadata jsonb not null default '{}'::jsonb
);

create unique index if not exists subscription_refund_open_charge_unique
  on public.subscription_refund_requests (charge_id)
  where status in ('requested', 'approved');

create index if not exists subscription_refund_requests_user_idx
  on public.subscription_refund_requests (user_id, requested_at desc);
create index if not exists subscription_refund_requests_status_idx
  on public.subscription_refund_requests (status, requested_at desc);

create index if not exists subscription_charges_user_status_idx
  on public.subscription_charges (user_id, status);
create index if not exists subscription_charges_subscription_idx
  on public.subscription_charges (subscription_id);
create index if not exists subscription_charge_attempts_charge_idx
  on public.subscription_charge_attempts (subscription_charge_id);
create index if not exists woovi_webhook_events_type_idx
  on public.woovi_webhook_events (event_type);
create index if not exists subscription_access_events_user_idx
  on public.subscription_access_events (user_id, created_at desc);

alter table public.subscription_charges enable row level security;
alter table public.subscription_charge_attempts enable row level security;
alter table public.woovi_webhook_events enable row level security;
alter table public.subscription_access_events enable row level security;
alter table public.subscription_refund_requests enable row level security;

drop policy if exists "Users can view own subscription charges" on public.subscription_charges;
create policy "Users can view own subscription charges"
  on public.subscription_charges for select
  using (auth.uid() = user_id);

drop policy if exists "Users can view own subscription access events" on public.subscription_access_events;
create policy "Users can view own subscription access events"
  on public.subscription_access_events for select
  using (auth.uid() = user_id);

drop policy if exists "Users can view own subscription charge attempts" on public.subscription_charge_attempts;
create policy "Users can view own subscription charge attempts"
  on public.subscription_charge_attempts for select
  using (
    exists (
      select 1
      from public.subscription_charges c
      where c.id = subscription_charge_id
        and c.user_id = auth.uid()
    )
  );

drop policy if exists "No direct user webhook reads" on public.woovi_webhook_events;
create policy "No direct user webhook reads"
  on public.woovi_webhook_events for select
  using (false);

drop policy if exists "Users can view own refund requests" on public.subscription_refund_requests;
create policy "Users can view own refund requests"
  on public.subscription_refund_requests for select
  using (auth.uid() = user_id or is_admin() or is_financeiro());

drop policy if exists "Finance can update refund requests" on public.subscription_refund_requests;
create policy "Finance can update refund requests"
  on public.subscription_refund_requests for update
  using (is_admin() or is_financeiro())
  with check (is_admin() or is_financeiro());

create or replace view public.current_user_payment_status as
select
  s.user_id,
  s.id as subscription_id,
  s.status as subscription_status,
  s.payment_access_status,
  case
    when s.status = 'active' and s.payment_access_status = 'allowed' then true
    when s.status = 'payment_pending' and s.payment_access_status in ('allowed', 'warning_pending') then true
    when s.status = 'cancelled' and s.current_period_end >= now() then true
    else false
  end as can_access,
  case
    when s.status = 'active' and s.payment_access_status = 'allowed' then true
    when s.status = 'payment_pending' and s.payment_access_status in ('allowed', 'warning_pending') then true
    when s.status = 'cancelled' and s.current_period_end >= now() then true
    else false
  end as can_use_qr,
  s.status in ('blocked', 'expired', 'rejected') as restore_required,
  s.payment_link_url,
  s.current_period_end,
  s.next_billing_date
from public.subscriptions s
where s.is_current = true;

create or replace function public.record_subscription_access_event(
  p_subscription_id uuid,
  p_user_id uuid,
  p_from_status public.subscription_status,
  p_to_status public.subscription_status,
  p_from_access_status public.payment_access_status,
  p_to_access_status public.payment_access_status,
  p_reason text,
  p_source text,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_id uuid;
begin
  insert into public.subscription_access_events (
    subscription_id,
    user_id,
    from_status,
    to_status,
    from_access_status,
    to_access_status,
    reason,
    source,
    metadata
  )
  values (
    p_subscription_id,
    p_user_id,
    p_from_status,
    p_to_status,
    p_from_access_status,
    p_to_access_status,
    p_reason,
    p_source,
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.request_subscription_refund(
  p_subscription_id uuid,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_charge public.subscription_charges%rowtype;
  v_has_usage boolean;
  v_request_id uuid;
begin
  select * into v_charge
  from public.subscription_charges
  where subscription_id = p_subscription_id
    and user_id = auth.uid()
    and status = 'paid'
  order by paid_at asc nulls last, created_at asc
  limit 1;

  if not found then
    raise exception 'Nenhuma cobrança paga elegível encontrada.';
  end if;

  if v_charge.paid_at is null or v_charge.paid_at < now() - interval '7 days' then
    raise exception 'Prazo de reembolso expirado.';
  end if;

  select exists (
    select 1
    from public.usage_records ur
    where ur.holder_user_id = auth.uid()
      and ur.used_at >= v_charge.paid_at
      and ur.used_at < v_charge.paid_at + interval '7 days'
  ) into v_has_usage;

  if v_has_usage then
    raise exception 'Reembolso indisponível após uso de benefício.';
  end if;

  insert into public.subscription_refund_requests (
    subscription_id,
    user_id,
    charge_id,
    reason,
    eligibility_checked_at,
    has_benefit_usage,
    metadata
  ) values (
    p_subscription_id,
    auth.uid(),
    v_charge.id,
    p_reason,
    now(),
    false,
    jsonb_build_object('manual_refund', true, 'policy_days', 7)
  )
  returning id into v_request_id;

  return v_request_id;
end;
$$;
