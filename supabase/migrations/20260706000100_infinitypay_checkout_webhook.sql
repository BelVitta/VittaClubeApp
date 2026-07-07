create table if not exists public.payment_intents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plan_id uuid not null references public.plans(id) on delete restrict,
  subscription_id uuid references public.subscriptions(id) on delete set null,
  provider text not null,
  order_nsu text not null unique,
  amount numeric(10,2) not null check (amount >= 0),
  amount_cents integer not null check (amount_cents >= 0),
  currency text not null default 'BRL',
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'failed', 'expired', 'cancelled')),
  checkout_url text,
  transaction_nsu text,
  slug text,
  receipt_url text,
  capture_method text,
  raw_latest_event jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  paid_at timestamptz
);

create index if not exists payment_intents_user_status_idx
  on public.payment_intents (user_id, status, created_at desc);

create index if not exists payment_intents_provider_status_idx
  on public.payment_intents (provider, status, created_at desc);

create table if not exists public.infinitypay_webhook_events (
  id uuid primary key default gen_random_uuid(),
  event_id text not null unique,
  order_nsu text,
  transaction_nsu text,
  slug text,
  processing_status text not null default 'received'
    check (processing_status in ('received', 'processed', 'failed')),
  processing_error text,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);

create index if not exists infinitypay_webhook_events_order_idx
  on public.infinitypay_webhook_events (order_nsu);

alter table public.payment_intents enable row level security;
alter table public.infinitypay_webhook_events enable row level security;

drop policy if exists "Users can view own payment intents" on public.payment_intents;
create policy "Users can view own payment intents"
  on public.payment_intents for select
  using (auth.uid() = user_id);

drop policy if exists "Users can create own payment intents" on public.payment_intents;
create policy "Users can create own payment intents"
  on public.payment_intents for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own pending payment intents" on public.payment_intents;
create policy "Users can update own pending payment intents"
  on public.payment_intents for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
