create table if not exists public.partner_applications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete set null,
  name text not null,
  category text not null,
  address text,
  phone text,
  email text not null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create index if not exists partner_applications_user_idx
  on public.partner_applications (user_id, created_at desc);

create index if not exists partner_applications_status_idx
  on public.partner_applications (status, created_at desc);

alter table public.partner_applications enable row level security;

drop policy if exists "Users can create partner applications" on public.partner_applications;
create policy "Users can create partner applications"
  on public.partner_applications for insert
  with check (auth.uid() is null or user_id = auth.uid());

drop policy if exists "Users can view own partner applications" on public.partner_applications;
create policy "Users can view own partner applications"
  on public.partner_applications for select
  using (user_id = auth.uid());

drop policy if exists "Admins can manage partner applications" on public.partner_applications;
create policy "Admins can manage partner applications"
  on public.partner_applications for all
  using (public.is_admin())
  with check (public.is_admin());
