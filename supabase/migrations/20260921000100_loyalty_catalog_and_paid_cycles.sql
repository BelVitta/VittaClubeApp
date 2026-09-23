-- Catálogo comercial do clube e evolução baseada em mensalidades aprovadas.
-- A migração é idempotente para poder ser aplicada em dev e produção.

alter table public.badges
  add column if not exists annual_draw_limit integer not null default 0;

do $$
begin
  alter table public.badges
    add constraint badges_annual_draw_limit_check check (annual_draw_limit >= -1);
exception when duplicate_object then null;
end $$;

-- Patentes são conteúdo público da página de adesão. As alterações continuam
-- restritas às políticas de admin/financeiro já existentes.
drop policy if exists "Anyone can view badges" on public.badges;
create policy "Anyone can view badges"
  on public.badges for select
  using (true);

insert into public.badges (
  level_name, display_name, sort_order, discount_percentage,
  max_consultations_per_month, required_months, required_consultations,
  required_referrals, requires_annual_plan, annual_draw_limit
)
values
  ('bronze', 'Bronze', 1, 10, 2, 1, 0, 0, false, 0),
  ('prata', 'Prata', 2, 10, 4, 3, 0, 0, false, 1),
  ('ouro', 'Ouro', 3, 15, 6, 6, 0, 0, false, 2),
  ('diamante', 'Diamante', 4, 20, 10, 12, 0, 0, false, -1)
on conflict (level_name) do update set
  display_name = excluded.display_name,
  sort_order = excluded.sort_order,
  discount_percentage = excluded.discount_percentage,
  required_months = excluded.required_months,
  required_consultations = 0,
  required_referrals = 0,
  requires_annual_plan = false,
  annual_draw_limit = excluded.annual_draw_limit,
  updated_at = now();

-- O produto oferece uma única assinatura mensal.
update public.plans
   set is_active = (subscription_type = 'mensal'),
       updated_at = now();

-- Mantém a promessa comercial da tela alinhada ao que o sistema entrega.
delete from public.plan_benefits b
using public.plans p
where b.plan_id = p.id and p.subscription_type = 'mensal';

insert into public.plan_benefits (plan_id, title, description, sort_order)
select p.id, benefit.title, benefit.description, benefit.sort_order
  from public.plans p
 cross join (values
   ('Descontos progressivos', 'Sua patente libera de 10% a 20% de desconto em consultas elegíveis.'::text, 1),
   ('Jornada de patentes', 'Bronze, Prata, Ouro e Diamante: cada mensalidade aprovada aproxima você do próximo nível.'::text, 2),
   ('Sorteios exclusivos', 'Ganhe participações anuais conforme sua patente: até 1, até 2 ou todos os sorteios.'::text, 3),
   ('Sem permanência mínima', 'Cancele quando quiser e preserve o progresso dos meses já pagos.'::text, 4)
 ) as benefit(title, description, sort_order)
 where p.subscription_type = 'mensal';

alter table public.badge_progress
  add column if not exists paid_months integer not null default 0;

create table if not exists public.membership_payment_cycles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  cycle_key text not null,
  paid_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, cycle_key)
);

create index if not exists membership_payment_cycles_user_idx
  on public.membership_payment_cycles (user_id, paid_at);

alter table public.membership_payment_cycles enable row level security;
drop policy if exists "Users can view own paid cycles" on public.membership_payment_cycles;
create policy "Users can view own paid cycles"
  on public.membership_payment_cycles for select
  using (auth.uid() = user_id);
drop policy if exists "Admins can view paid cycles" on public.membership_payment_cycles;
create policy "Admins can view paid cycles"
  on public.membership_payment_cycles for select
  using (is_admin() or is_financeiro());
revoke insert, update, delete on public.membership_payment_cycles from anon, authenticated;

create or replace function public.record_membership_payment_cycle(
  p_user_id uuid,
  p_subscription_id uuid,
  p_cycle_key text,
  p_paid_at timestamptz default now()
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_paid_months integer;
  v_level badge_level;
begin
  insert into public.membership_payment_cycles
    (user_id, subscription_id, cycle_key, paid_at)
  values (p_user_id, p_subscription_id, p_cycle_key, coalesce(p_paid_at, now()))
  on conflict (user_id, cycle_key) do nothing;

  select count(*)::integer into v_paid_months
    from public.membership_payment_cycles
   where user_id = p_user_id;

  select level_name into v_level
    from public.badges
   where required_months <= v_paid_months
   order by required_months desc, sort_order desc
   limit 1;

  update public.badge_progress
     set paid_months = v_paid_months,
         current_badge_level = coalesce(v_level, 'bronze'::badge_level),
         last_upgrade_at = case
           when current_badge_level is distinct from coalesce(v_level, 'bronze'::badge_level)
           then now() else last_upgrade_at end
   where user_id = p_user_id;

  update public.subscriptions
     set badge_level = coalesce(v_level, 'bronze'::badge_level),
         plan_level_status = coalesce(v_level, 'bronze'::badge_level)
   where user_id = p_user_id and is_current = true;
end;
$$;

revoke execute on function public.record_membership_payment_cycle(uuid, uuid, text, timestamptz)
  from public, anon, authenticated;

-- Reconstitui o histórico que já existe antes de ativar a nova regra.
insert into public.membership_payment_cycles
  (user_id, subscription_id, cycle_key, paid_at)
select p.user_id, p.subscription_id,
       coalesce(to_char(p.paid_at at time zone 'UTC', 'YYYY-MM'), p.id::text),
       coalesce(p.paid_at, p.created_at)
  from public.payments p
 where p.subscription_id is not null
   and p.status = 'aprovado'
on conflict (user_id, cycle_key) do nothing;

insert into public.membership_payment_cycles
  (user_id, subscription_id, cycle_key, paid_at)
select p.user_id, p.subscription_id,
       coalesce(to_char(p.paid_at at time zone 'UTC', 'YYYY-MM'), p.provider_payment_id),
       coalesce(p.paid_at, p.created_at)
  from public.mercadopago_authorized_payments p
 where p.status = 'approved'
on conflict (user_id, cycle_key) do nothing;

do $$
declare
  v_user record;
begin
  for v_user in select distinct user_id from public.membership_payment_cycles loop
    perform public.record_membership_payment_cycle(
      v_user.user_id,
      (select subscription_id from public.membership_payment_cycles
        where user_id = v_user.user_id order by paid_at desc limit 1),
      (select cycle_key from public.membership_payment_cycles
        where user_id = v_user.user_id order by paid_at desc limit 1),
      now()
    );
  end loop;
end;
$$;

create or replace function public.trg_record_subscription_cycle()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_period_changed boolean;
begin
  if tg_op = 'INSERT' then
    v_period_changed := true;
  else
    v_period_changed := old.current_period_start is distinct from new.current_period_start;
  end if;
  if new.current_period_start is not null
     and v_period_changed
     and new.current_period_end is not null
     and new.current_period_end >= new.current_period_start then
    perform public.record_membership_payment_cycle(
      new.user_id,
      new.id,
      to_char(new.current_period_start at time zone 'UTC', 'YYYY-MM'),
      new.current_period_start
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_subscription_paid_cycle on public.subscriptions;
create trigger trg_subscription_paid_cycle
  after insert or update of current_period_start on public.subscriptions
  for each row execute function public.trg_record_subscription_cycle();

-- Pagamentos avulsos também podem comprovar uma mensalidade.
create or replace function public.trg_record_payment_cycle()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'aprovado' and new.subscription_id is not null then
    perform public.record_membership_payment_cycle(
      new.user_id,
      new.subscription_id,
      coalesce(to_char(new.paid_at at time zone 'UTC', 'YYYY-MM'), new.id::text),
      coalesce(new.paid_at, new.created_at)
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_payment_paid_cycle on public.payments;
create trigger trg_payment_paid_cycle
  after insert or update of status, paid_at on public.payments
  for each row execute function public.trg_record_payment_cycle();

-- Inscrição segura em sorteios: o limite anual é da patente no momento da
-- inscrição e nunca pode ser contornado por chamadas concorrentes à API.
drop policy if exists "Users can register for draws" on public.draw_participants;

create or replace function public.register_for_draw(p_draw_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_draw public.draws;
  v_sub public.subscriptions;
  v_limit integer;
  v_used integer;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado';
  end if;

  select * into v_draw from public.draws where id = p_draw_id for update;
  if not found or v_draw.status <> 'inscricoes_abertas' then
    raise exception 'Sorteio indisponível para inscrição';
  end if;
  if v_draw.registration_start_date is not null
     and now() < v_draw.registration_start_date then
    raise exception 'As inscrições ainda não começaram';
  end if;
  if v_draw.registration_end_date is not null
     and now() > v_draw.registration_end_date then
    raise exception 'As inscrições foram encerradas';
  end if;

  select * into v_sub
    from public.subscriptions
   where user_id = v_user_id
     and is_current = true
     and current_period_end is not null
     and current_period_end >= now()
   for update;
  if not found then
    raise exception 'Assinatura ativa necessária';
  end if;

  if array_length(v_draw.eligible_plan_levels, 1) > 0
     and not (v_sub.badge_level = any(v_draw.eligible_plan_levels)) then
    raise exception 'Sua patente não é elegível para este sorteio';
  end if;

  select coalesce(annual_draw_limit, 0) into v_limit
    from public.badges where level_name = v_sub.badge_level;
  if v_limit = 0 then
    raise exception 'Sua patente ainda não inclui participação em sorteios';
  end if;

  if exists (select 1 from public.draw_participants
              where draw_id = p_draw_id and user_id = v_user_id) then
    return jsonb_build_object('registered', true, 'already_registered', true);
  end if;

  if v_limit > 0 then
    select count(*)::integer into v_used
      from public.draw_participants dp
      join public.draws d on d.id = dp.draw_id
     where dp.user_id = v_user_id
       and extract(year from d.draw_date) = extract(year from v_draw.draw_date)
       and d.status <> 'cancelado';
    if v_used >= v_limit then
      raise exception 'Limite anual de sorteios já utilizado';
    end if;
  end if;

  insert into public.draw_participants (draw_id, user_id)
  values (p_draw_id, v_user_id)
  on conflict (draw_id, user_id) do nothing;
  return jsonb_build_object('registered', true, 'already_registered', false);
end;
$$;

revoke all on function public.register_for_draw(uuid) from public, anon;
grant execute on function public.register_for_draw(uuid) to authenticated;
