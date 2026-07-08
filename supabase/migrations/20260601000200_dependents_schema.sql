-- Dependents module schema.

create type public.dependent_status as enum ('active', 'inactive');
create type public.beneficiary_type as enum ('holder', 'dependent');
create type public.dependent_appointment_status as enum (
  'agendado',
  'utilizado',
  'cancelado',
  'expirado'
);

create table if not exists public.dependents (
  id uuid primary key default gen_random_uuid(),
  holder_user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  cpf text not null,
  birth_date date not null,
  relationship text not null,
  status public.dependent_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists dependents_active_cpf_unique
  on public.dependents (cpf)
  where status = 'active';

create index if not exists dependents_holder_status_idx
  on public.dependents (holder_user_id, status);

create table if not exists public.dependent_appointments (
  id uuid primary key default gen_random_uuid(),
  holder_user_id uuid not null references auth.users(id) on delete cascade,
  beneficiary_type public.beneficiary_type not null,
  beneficiary_id uuid,
  establishment_id uuid,
  scheduled_at timestamptz not null,
  status public.dependent_appointment_status not null default 'agendado',
  qr_token text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint dependent_appointments_beneficiary_check check (
    (beneficiary_type = 'holder' and beneficiary_id is null)
    or (beneficiary_type = 'dependent' and beneficiary_id is not null)
  )
);

create index if not exists dependent_appointments_holder_idx
  on public.dependent_appointments (holder_user_id, scheduled_at desc);

create index if not exists dependent_appointments_beneficiary_status_idx
  on public.dependent_appointments (beneficiary_type, beneficiary_id, status);

create table if not exists public.usage_records (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null unique references public.dependent_appointments(id),
  holder_user_id uuid not null references auth.users(id) on delete cascade,
  beneficiary_type public.beneficiary_type not null,
  beneficiary_id uuid,
  cycle_reference text not null,
  used_at timestamptz not null default now(),
  constraint usage_records_beneficiary_check check (
    (beneficiary_type = 'holder' and beneficiary_id is null)
    or (beneficiary_type = 'dependent' and beneficiary_id is not null)
  )
);

create index if not exists usage_records_quota_count_idx
  on public.usage_records (holder_user_id, beneficiary_type, beneficiary_id, cycle_reference);

alter table public.dependents enable row level security;
alter table public.dependent_appointments enable row level security;
alter table public.usage_records enable row level security;
