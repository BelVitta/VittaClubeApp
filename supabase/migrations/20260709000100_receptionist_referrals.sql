-- Ranking de indicações das recepcionistas.
--
-- Quem tem role = 'admin' já É a recepcionista (não existe papel novo).
-- Cada admin ganha um receptionist_code único, informado pelo indicado no
-- cadastro. A indicação só vira "conversão" quando o indicado ativa a
-- PRIMEIRA assinatura da vida dele (renovação/reativação não gera novo
-- crédito) — daí o flag profiles.first_subscription_converted_at, que é a
-- fonte da verdade dessa regra. O valor creditado é o preço do plano no
-- momento da conversão, gravado uma única vez (month_reference), e depois
-- disso a linha só muda por correção manual do financeiro via RPC auditada
-- (não existe policy de UPDATE direta pra authenticated).

-- ------------------------------------------------------------------
-- Colunas novas em profiles
-- ------------------------------------------------------------------
alter table public.profiles
  add column if not exists receptionist_code text,
  add column if not exists first_subscription_converted_at timestamptz;

create unique index if not exists idx_profiles_receptionist_code_unique
  on public.profiles (receptionist_code)
  where receptionist_code is not null;

-- ------------------------------------------------------------------
-- Geração automática do código quando o usuário vira admin
-- ------------------------------------------------------------------
create or replace function public.generate_receptionist_code()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_base text;
  v_candidate text;
  v_attempt int := 0;
begin
  if new.role = 'admin' and new.receptionist_code is null then
    v_base := upper(regexp_replace(coalesce(new.name, ''), '[^a-zA-Z]', '', 'g'));
    v_base := left(nullif(v_base, ''), 3);
    v_base := coalesce(v_base, 'ADM');

    loop
      v_candidate := v_base || lpad(floor(random() * 10000)::int::text, 4, '0');
      exit when not exists (
        select 1 from public.profiles where receptionist_code = v_candidate
      );
      v_attempt := v_attempt + 1;
      exit when v_attempt > 20;
    end loop;

    if v_attempt > 20 then
      v_candidate := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8));
    end if;

    new.receptionist_code := v_candidate;
  end if;

  return new;
end;
$$;

drop trigger if exists assign_receptionist_code on public.profiles;
create trigger assign_receptionist_code
  before insert or update of role on public.profiles
  for each row
  execute function public.generate_receptionist_code();

-- Cobre os admins que já existem antes desta migration.
update public.profiles
   set role = role
 where role = 'admin'
   and receptionist_code is null;

-- ------------------------------------------------------------------
-- Tabela de indicações
-- ------------------------------------------------------------------
create table if not exists public.receptionist_referrals (
  id uuid primary key default gen_random_uuid(),
  receptionist_id uuid not null references public.profiles(id),
  referral_code text not null,
  referred_user_id uuid not null unique references public.profiles(id),
  status text not null default 'pending' check (status in ('pending', 'converted')),
  converted_at timestamptz,
  plan_id_at_conversion uuid references public.plans(id),
  plan_price_at_conversion numeric(10,2),
  month_reference text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_receptionist_referrals_receptionist
  on public.receptionist_referrals (receptionist_id);
create index if not exists idx_receptionist_referrals_status
  on public.receptionist_referrals (status);
create index if not exists idx_receptionist_referrals_month
  on public.receptionist_referrals (month_reference);

alter table public.receptionist_referrals enable row level security;

-- Só leitura direta pra authenticated (mesmo padrão de usage_records em
-- dependents: escrita só via função security definer). Admin e financeiro
-- veem tudo, igual ao resto do painel administrativo (is_admin() já é o
-- padrão usado em todas as outras tabelas geridas pelo admin panel).
drop policy if exists "Receptionists and finance can view referrals" on public.receptionist_referrals;
create policy "Receptionists and finance can view referrals"
  on public.receptionist_referrals for select
  using (receptionist_id = auth.uid() or public.is_admin() or public.is_financeiro());

-- ------------------------------------------------------------------
-- Atribuição no cadastro: estende handle_new_user() para resolver o
-- receptionist_code informado no signup (raw_user_meta_data). Código
-- inválido/ausente nunca bloqueia o cadastro.
-- ------------------------------------------------------------------
create or replace function handle_new_user()
returns trigger as $$
declare
    v_cpf   text := nullif(NEW.raw_user_meta_data->>'cpf', '');
    v_phone text := nullif(NEW.raw_user_meta_data->>'phone', '');
    v_name  text := coalesce(
        nullif(NEW.raw_user_meta_data->>'name', ''),
        nullif(NEW.raw_user_meta_data->>'full_name', ''),  -- Google envia assim
        split_part(NEW.email, '@', 1)
    );
    v_receptionist_code text := upper(nullif(NEW.raw_user_meta_data->>'receptionist_code', ''));
    v_receptionist_id uuid;
BEGIN
    INSERT INTO public.profiles (
        id, name, email, cpf_encrypted, cpf_hash, phone_encrypted, role, avatar_url
    )
    VALUES (
        NEW.id,
        v_name,
        NEW.email,
        CASE WHEN v_cpf   IS NOT NULL THEN encrypt_sensitive(v_cpf) END,
        CASE WHEN v_cpf   IS NOT NULL THEN hash_cpf(v_cpf)         END,
        CASE WHEN v_phone IS NOT NULL THEN encrypt_sensitive(v_phone) END,
        'user',
        NEW.raw_user_meta_data->>'avatar_url'
    );

    if v_receptionist_code is not null then
        select id into v_receptionist_id
          from public.profiles
         where receptionist_code = v_receptionist_code
           and role = 'admin';

        if v_receptionist_id is not null then
            insert into public.receptionist_referrals (receptionist_id, referral_code, referred_user_id)
            values (v_receptionist_id, v_receptionist_code, NEW.id)
            on conflict (referred_user_id) do nothing;
        end if;
    end if;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Nunca bloquear o signup por falha na criação do perfil/indicação.
    RAISE WARNING 'handle_new_user failed for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------------
-- Conversão: dispara quando uma subscription vira 'active' (InfinityPay
-- insere a linha já ativa; Woovi faz update de status — os dois caminhos
-- passam por aqui). Só credita a indicação na PRIMEIRA ativação da vida do
-- usuário; reativação/renovação não gera novo crédito.
-- ------------------------------------------------------------------
create or replace function public.handle_subscription_activated()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_plan_price numeric(10,2);
  v_referral_id uuid;
begin
  update public.profiles
     set first_subscription_converted_at = now()
   where id = new.user_id
     and first_subscription_converted_at is null;

  if not found then
    -- Já tinha convertido antes: reativação/renovação, sem novo crédito.
    return new;
  end if;

  select price into v_plan_price from public.plans where id = new.plan_id;

  update public.receptionist_referrals
     set status = 'converted',
         converted_at = now(),
         plan_id_at_conversion = new.plan_id,
         plan_price_at_conversion = v_plan_price,
         month_reference = to_char(now(), 'YYYY-MM'),
         updated_at = now()
   where referred_user_id = new.user_id
     and status = 'pending'
  returning id into v_referral_id;

  if v_referral_id is not null then
    insert into public.audit_log (actor_id, actor_role, action, entity_type, entity_id, metadata)
    values (
      new.user_id, 'system', 'referral_conversion_confirmed', 'receptionist_referral', v_referral_id,
      jsonb_build_object('subscription_id', new.id, 'plan_id', new.plan_id, 'plan_price', v_plan_price)
    );
  end if;

  return new;
end;
$$;

drop trigger if exists handle_subscription_activated on public.subscriptions;
create trigger handle_subscription_activated
  after insert or update of status on public.subscriptions
  for each row
  when (new.status = 'active')
  execute function public.handle_subscription_activated();

-- ------------------------------------------------------------------
-- Correção manual (financeiro only). Único jeito de alterar uma linha após
-- a conversão — a tabela não tem policy de UPDATE pra authenticated.
-- ------------------------------------------------------------------
create or replace function public.correct_receptionist_referral(
  p_referral_id uuid,
  p_new_receptionist_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old_receptionist_id uuid;
  v_caller_role text;
begin
  select role into v_caller_role from public.profiles where id = auth.uid();

  if v_caller_role is distinct from 'financeiro' then
    raise exception 'Somente o financeiro pode corrigir atribuições de indicação.';
  end if;

  if p_new_receptionist_id = auth.uid() then
    raise exception 'Não é permitido atribuir a indicação a si mesmo.';
  end if;

  select receptionist_id into v_old_receptionist_id
    from public.receptionist_referrals
   where id = p_referral_id;

  if v_old_receptionist_id is null then
    raise exception 'Indicação não encontrada.';
  end if;

  update public.receptionist_referrals
     set receptionist_id = p_new_receptionist_id,
         updated_at = now()
   where id = p_referral_id;

  insert into public.audit_log (actor_id, actor_role, action, entity_type, entity_id, metadata)
  values (
    auth.uid(), v_caller_role, 'referral_manual_correction', 'receptionist_referral', p_referral_id,
    jsonb_build_object(
      'old_receptionist_id', v_old_receptionist_id,
      'new_receptionist_id', p_new_receptionist_id,
      'reason', p_reason
    )
  );
end;
$$;

revoke all on function public.correct_receptionist_referral(uuid, uuid, text) from public;
grant execute on function public.correct_receptionist_referral(uuid, uuid, text) to authenticated;

-- ------------------------------------------------------------------
-- Ranking mensal agregado (RPC em vez de view pra aceitar o mês como
-- parâmetro). Restrito a admin/financeiro.
-- ------------------------------------------------------------------
create or replace function public.get_receptionist_monthly_ranking(p_month_reference text)
returns table (
  receptionist_id uuid,
  receptionist_name text,
  receptionist_code text,
  indicacoes_count bigint,
  conversoes_count bigint,
  total_gerado numeric
)
language plpgsql
security definer
stable
set search_path = public
as $$
begin
  if not (public.is_admin() or public.is_financeiro()) then
    raise exception 'Acesso restrito a administradores e financeiro.';
  end if;

  return query
    select
      p.id,
      p.name,
      p.receptionist_code,
      count(rr.id) filter (
        where rr.created_at >= to_date(p_month_reference || '-01', 'YYYY-MM-DD')
          and rr.created_at < (to_date(p_month_reference || '-01', 'YYYY-MM-DD') + interval '1 month')
      ) as indicacoes_count,
      count(rr.id) filter (where rr.month_reference = p_month_reference) as conversoes_count,
      coalesce(
        sum(rr.plan_price_at_conversion) filter (where rr.month_reference = p_month_reference),
        0
      ) as total_gerado
    from public.profiles p
    left join public.receptionist_referrals rr on rr.receptionist_id = p.id
    where p.role = 'admin'
    group by p.id, p.name, p.receptionist_code
    order by conversoes_count desc, total_gerado desc, p.name asc;
end;
$$;

revoke all on function public.get_receptionist_monthly_ranking(text) from public;
grant execute on function public.get_receptionist_monthly_ranking(text) to authenticated;
