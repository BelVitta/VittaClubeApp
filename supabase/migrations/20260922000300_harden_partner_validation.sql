-- Partner confirmations must be tied to a recent, server-issued validation.
-- The client may provide only the validation id and the optional purchase
-- amount. Beneficiary, member name, plan level and discount are resolved again
-- inside this transaction.

create table if not exists public.partner_validation_sessions (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null references public.partners(id) on delete cascade,
  actor_user_id uuid not null references auth.users(id) on delete cascade,
  holder_user_id uuid not null references public.profiles(id) on delete cascade,
  dependent_id uuid references public.dependents(id) on delete set null,
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  beneficiary_type text not null check (beneficiary_type in ('holder', 'dependent')),
  expires_at timestamptz not null default (now() + interval '5 minutes'),
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists partner_validation_sessions_actor_idx
  on public.partner_validation_sessions (actor_user_id, created_at desc);
create index if not exists partner_validation_sessions_expiry_idx
  on public.partner_validation_sessions (expires_at)
  where consumed_at is null;

alter table public.partner_validation_sessions enable row level security;
revoke all on table public.partner_validation_sessions from public, anon, authenticated;
grant select, insert, update, delete on public.partner_validation_sessions to service_role;

-- Replace the public wrapper so an approved scan creates a short-lived,
-- partner-bound session. The underlying validation RPCs remain the source of
-- truth for the eligibility decision.
create or replace function public.validate_loyalty_card(
  p_payload text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_result jsonb;
  v_session_id uuid;
  v_partner_id uuid;
  v_holder_user_id uuid;
  v_dependent_id uuid;
  v_subscription_id uuid;
  v_beneficiary_type text;
begin
  if not public.try_consume_rate_limit('loyalty_validate', 30, 60) then
    return public.rate_limited_decision();
  end if;

  v_result := public.validate_loyalty_card_inner(p_payload, p_actor_user_id);

  if v_result->>'decision' <> 'approved'
     or auth.uid() is null
     or p_actor_user_id <> auth.uid()
     or not public.is_parceiro() then
    return v_result;
  end if;

  begin
    v_partner_id := (v_result->>'partner_id')::uuid;
    v_holder_user_id := (v_result->>'holder_user_id')::uuid;
    v_subscription_id := (v_result->>'subscription_id')::uuid;
    v_dependent_id := nullif(v_result->>'dependent_id', '')::uuid;
  exception when invalid_text_representation then
    return jsonb_build_object(
      'decision', 'refused',
      'message', 'Validação aprovada sem vínculo de segurança válido.'
    );
  end;

  v_beneficiary_type := coalesce(v_result->>'beneficiary_type', 'holder');
  if v_partner_id is null
     or v_holder_user_id is null
     or v_subscription_id is null
     or v_beneficiary_type not in ('holder', 'dependent')
     or (v_beneficiary_type = 'dependent' and v_dependent_id is null)
     or (v_beneficiary_type = 'holder' and v_dependent_id is not null) then
    return jsonb_build_object(
      'decision', 'refused',
      'message', 'Validação aprovada sem beneficiário completo.'
    );
  end if;

  if not exists (
    select 1
      from public.partners p
     where p.id = v_partner_id
       and p.profile_id = auth.uid()
       and p.is_active = true
  ) then
    return jsonb_build_object(
      'decision', 'refused',
      'message', 'Estabelecimento parceiro inativo ou não encontrado.'
    );
  end if;

  insert into public.partner_validation_sessions (
    partner_id,
    actor_user_id,
    holder_user_id,
    dependent_id,
    subscription_id,
    beneficiary_type
  ) values (
    v_partner_id,
    auth.uid(),
    v_holder_user_id,
    v_dependent_id,
    v_subscription_id,
    v_beneficiary_type
  )
  returning id into v_session_id;

  return v_result || jsonb_build_object(
    'validation_id', v_session_id,
    'validation_expires_at', now() + interval '5 minutes'
  );
end;
$$;

-- Remove the old API that accepted holder/name/dependent/plan values from the
-- client. The inner implementation is intentionally left without privileges
-- for backwards-compatible migration ordering, but is not callable by users.
revoke all on function public.confirm_partner_validation(uuid, text, uuid, numeric, text)
  from public, anon, authenticated;
drop function if exists public.confirm_partner_validation(uuid, text, uuid, numeric, text);

create or replace function public.confirm_partner_validation(
  p_validation_id uuid,
  p_original_value numeric default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_session public.partner_validation_sessions%rowtype;
  v_partner public.partners%rowtype;
  v_sub public.subscriptions%rowtype;
  v_dep public.dependents%rowtype;
  v_member_name text;
  v_pct numeric(5,2);
  v_savings numeric(10,2) := 0;
  v_id uuid;
begin
  if not public.try_consume_rate_limit('partner_confirm', 20, 60) then
    return jsonb_build_object(
      'ok', false,
      'message', 'Muitas tentativas. Aguarde um minuto e tente novamente.'
    );
  end if;

  if auth.uid() is null or not public.is_parceiro() then
    return jsonb_build_object('ok', false, 'message', 'Operação não autorizada.');
  end if;

  if p_original_value is not null
     and (p_original_value <= 0 or p_original_value > 100000000) then
    return jsonb_build_object('ok', false, 'message', 'Valor da compra inválido.');
  end if;

  -- Locking the session makes confirmation one-time even under concurrent taps.
  select s.*
    into v_session
    from public.partner_validation_sessions s
   where s.id = p_validation_id
     and s.actor_user_id = auth.uid()
     and s.consumed_at is null
   for update;

  if not found then
    return jsonb_build_object(
      'ok', false,
      'message', 'Validação inexistente, já utilizada ou pertencente a outro aparelho.'
    );
  end if;

  if v_session.expires_at <= now() then
    return jsonb_build_object(
      'ok', false,
      'message', 'A validação expirou. Leia a carteirinha novamente.'
    );
  end if;

  select p.*
    into v_partner
    from public.partners p
   where p.id = v_session.partner_id
     and p.profile_id = auth.uid()
     and p.is_active = true
   for update;
  if not found then
    return jsonb_build_object('ok', false, 'message', 'Parceiro inativo.');
  end if;

  -- Re-resolve the current subscription; the scan result is not trusted for
  -- the final write.
  select s.*
    into v_sub
    from public.subscriptions s
   where s.id = v_session.subscription_id
     and s.user_id = v_session.holder_user_id
     and s.is_current = true
   for update;
  if not found or not public.holder_can_use_qr(v_sub) then
    return jsonb_build_object(
      'ok', false,
      'message', 'A assinatura não está elegível para este benefício.'
    );
  end if;

  if v_session.beneficiary_type = 'dependent' then
    select d.*
      into v_dep
      from public.dependents d
     where d.id = v_session.dependent_id
       and d.holder_user_id = v_session.holder_user_id
       and d.status = 'active'::public.dependent_status
     for update;
    if not found then
      return jsonb_build_object(
        'ok', false,
        'message', 'O dependente não está mais elegível.'
      );
    end if;
    v_member_name := v_dep.name;
  else
    select p.name
      into v_member_name
      from public.profiles p
     where p.id = v_session.holder_user_id;
    if v_member_name is null then
      return jsonb_build_object('ok', false, 'message', 'Membro não encontrado.');
    end if;
  end if;

  v_pct := coalesce(v_partner.discount_percentage, 0);
  if p_original_value is not null then
    v_savings := round(p_original_value * v_pct / 100.0, 2);
  end if;

  insert into public.partner_validations (
    partner_id,
    user_id,
    service_id,
    user_name,
    user_badge_level,
    discount_applied,
    service_name,
    discount_percentage,
    original_value,
    savings_amount,
    beneficiary_type,
    dependent_id
  ) values (
    v_partner.id,
    v_session.holder_user_id,
    null,
    v_member_name,
    v_sub.plan_level_status::text,
    v_savings,
    'Carteirinha Vita Clube',
    v_pct,
    p_original_value,
    v_savings,
    v_session.beneficiary_type,
    v_session.dependent_id
  )
  returning id into v_id;

  update public.partner_validation_sessions
     set consumed_at = now()
   where id = v_session.id;

  return jsonb_build_object(
    'ok', true,
    'id', v_id,
    'validation_id', v_session.id,
    'discount_percentage', v_pct,
    'savings_amount', v_savings,
    'original_value', p_original_value,
    'beneficiary_type', v_session.beneficiary_type,
    'member_name', v_member_name
  );
end;
$$;

revoke all on function public.validate_loyalty_card(text, uuid) from public, anon;
revoke all on function public.confirm_partner_validation(uuid, numeric) from public, anon;
grant execute on function public.validate_loyalty_card(text, uuid) to authenticated;
grant execute on function public.confirm_partner_validation(uuid, numeric) to authenticated;

