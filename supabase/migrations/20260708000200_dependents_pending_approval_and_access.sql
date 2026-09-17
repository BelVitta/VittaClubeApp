-- Dependentes: fluxo de aprovação presencial (pending -> active) + RLS que
-- faltava por completo nas 3 tabelas do módulo (dependents,
-- dependent_appointments, usage_records tinham RLS habilitado mas nenhuma
-- policy, ou seja, ficavam inacessíveis para qualquer cliente autenticado).

-- ------------------------------------------------------------------
-- Colunas de aprovação + default novo
-- ------------------------------------------------------------------
alter table public.dependents
  add column if not exists approved_by uuid references public.profiles(id),
  add column if not exists approved_at timestamptz,
  add column if not exists rejection_reason text;

alter table public.dependents alter column status set default 'pending';

-- CPF único agora cobre pending+active (evita fila de cadastros duplicados
-- aguardando aprovação).
drop index if exists dependents_active_cpf_unique;
create unique index if not exists dependents_active_pending_cpf_unique
  on public.dependents (cpf)
  where status in ('active', 'pending');

-- ------------------------------------------------------------------
-- Cadastro sempre nasce pending, não importa o que o client mande.
-- ------------------------------------------------------------------
create or replace function public.force_dependent_pending_on_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.status := 'pending';
  new.approved_by := null;
  new.approved_at := null;
  return new;
end;
$$;

drop trigger if exists force_dependent_pending_on_insert on public.dependents;
create trigger force_dependent_pending_on_insert
  before insert on public.dependents
  for each row
  execute function public.force_dependent_pending_on_insert();

-- Só admin pode aprovar (pending/inactive -> active). Titular continua
-- podendo desativar (-> inactive) o próprio dependente livremente.
create or replace function public.prevent_dependent_self_approval()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status
     and new.status = 'active'
     and not public.is_admin() then
    raise exception 'Somente um administrador pode aprovar um dependente.';
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_dependent_self_approval on public.dependents;
create trigger prevent_dependent_self_approval
  before update on public.dependents
  for each row
  execute function public.prevent_dependent_self_approval();

-- ------------------------------------------------------------------
-- RLS — dependents
-- ------------------------------------------------------------------
drop policy if exists "Holders can view own dependents" on public.dependents;
create policy "Holders can view own dependents"
  on public.dependents for select
  using (holder_user_id = auth.uid() or public.is_admin());

drop policy if exists "Holders can create own dependents" on public.dependents;
create policy "Holders can create own dependents"
  on public.dependents for insert
  with check (holder_user_id = auth.uid() or public.is_admin());

drop policy if exists "Holders and admins can update dependents" on public.dependents;
create policy "Holders and admins can update dependents"
  on public.dependents for update
  using (holder_user_id = auth.uid() or public.is_admin())
  with check (holder_user_id = auth.uid() or public.is_admin());

-- ------------------------------------------------------------------
-- RLS — dependent_appointments
-- ------------------------------------------------------------------
drop policy if exists "Holders can view own appointments" on public.dependent_appointments;
create policy "Holders can view own appointments"
  on public.dependent_appointments for select
  using (holder_user_id = auth.uid() or public.is_admin());

drop policy if exists "Holders can create own appointments" on public.dependent_appointments;
create policy "Holders can create own appointments"
  on public.dependent_appointments for insert
  with check (holder_user_id = auth.uid());

drop policy if exists "Holders and admins can update appointments" on public.dependent_appointments;
create policy "Holders and admins can update appointments"
  on public.dependent_appointments for update
  using (holder_user_id = auth.uid() or public.is_admin())
  with check (holder_user_id = auth.uid() or public.is_admin());

-- ------------------------------------------------------------------
-- RLS — usage_records (somente leitura pelo client; escrita só via RPC
-- security definer validate_dependent_qr)
-- ------------------------------------------------------------------
drop policy if exists "Holders can view own usage records" on public.usage_records;
create policy "Holders can view own usage records"
  on public.usage_records for select
  using (holder_user_id = auth.uid() or public.is_admin());

-- ------------------------------------------------------------------
-- Endurecer validate_dependent_qr (mesma postura de validate_member_qr,
-- que já tinha REVOKE/GRANT explícitos).
-- ------------------------------------------------------------------
revoke all on function public.validate_dependent_qr(text, uuid, uuid) from public;
grant execute on function public.validate_dependent_qr(text, uuid, uuid) to authenticated;

-- ------------------------------------------------------------------
-- Novo default de negócio: 1 uso/mês por dependente (era 2).
-- ------------------------------------------------------------------
update public.clinic_settings
   set value = '1', updated_at = now()
 where key = 'monthly_uses_per_dependent';

-- ------------------------------------------------------------------
-- Agendar expiração automática de agendamentos parados (antes só existia
-- a função, nunca era chamada por ninguém).
-- ------------------------------------------------------------------
create extension if not exists pg_cron;

select cron.schedule(
  'expire-stale-dependent-appointments',
  '*/15 * * * *',
  $$select public.expire_stale_dependent_appointments();$$
);
