-- Harden role permissions before client release.

create or replace function public.is_admin()
returns boolean
language plpgsql
security definer
stable
as $$
begin
  return exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role in ('admin', 'financeiro')
  );
end;
$$;

create or replace function public.is_admin_or_financeiro()
returns boolean
language plpgsql
security definer
stable
as $$
begin
  return exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role in ('admin', 'financeiro')
  );
end;
$$;

create or replace function public.prevent_non_financeiro_role_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.role is distinct from new.role and not public.is_financeiro() then
    raise exception 'Apenas financeiro pode alterar perfil de acesso.';
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_non_financeiro_role_change on public.profiles;
create trigger prevent_non_financeiro_role_change
  before update on public.profiles
  for each row
  execute function public.prevent_non_financeiro_role_change();

drop policy if exists "Admins can manage all profiles" on public.profiles;
drop policy if exists "Admins can view all profiles" on public.profiles;
drop policy if exists "Financeiro can view profiles" on public.profiles;
drop policy if exists "Admins can update profiles" on public.profiles;
drop policy if exists "Financeiro can manage profiles" on public.profiles;

create policy "Admins can view all profiles"
  on public.profiles for select
  using (public.is_admin_or_financeiro());

create policy "Admins can update profiles"
  on public.profiles for update
  using (public.is_admin())
  with check (public.is_admin());

create policy "Financeiro can manage profiles"
  on public.profiles for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

drop policy if exists "Admins can manage partner applications" on public.partner_applications;
create policy "Admins can manage partner applications"
  on public.partner_applications for all
  using (public.is_admin_or_financeiro())
  with check (public.is_admin_or_financeiro());
