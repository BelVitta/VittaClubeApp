-- Enrich validate_dependent_qr approved payload with beneficiary identity
-- so reception can confirm who is at the counter (ALA-29 / identity gate).
--
-- New fields on approved (and some refusal) responses:
--   member_name       : name of the beneficiary (holder profile OR dependent)
--   holder_name       : name of the holder (when beneficiary is a dependent)
--   beneficiary_type  : 'holder' | 'dependent'

create or replace function public.validate_dependent_qr(
  p_qr_token text,
  p_actor_user_id uuid,
  p_establishment_id uuid default null
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_appointment public.dependent_appointments%rowtype;
  v_dependent public.dependents%rowtype;
  v_subscription public.subscriptions%rowtype;
  v_cycle_reference text;
  v_limit int;
  v_used_count int;
  v_usage_id uuid;
  v_discount numeric(5,2) := 0;
  v_member_name text;
  v_holder_name text;
  v_beneficiary_type text;
  v_dependent_found boolean := false;
begin
  select *
    into v_appointment
    from public.dependent_appointments
   where qr_token = p_qr_token
   for update;

  if not found then
    return jsonb_build_object('decision', 'invalid_token', 'message', 'QR invalido.');
  end if;

  v_beneficiary_type := v_appointment.beneficiary_type::text;

  select name
    into v_holder_name
    from public.profiles
   where id = v_appointment.holder_user_id;

  if v_appointment.beneficiary_type = 'dependent' then
    select *
      into v_dependent
      from public.dependents
     where id = v_appointment.beneficiary_id
     for update;

    v_dependent_found := found;
    if v_dependent_found then
      v_member_name := v_dependent.name;
    end if;
  else
    v_member_name := v_holder_name;
  end if;

  if v_appointment.status = 'utilizado' then
    select id into v_usage_id
      from public.usage_records
     where appointment_id = v_appointment.id
     limit 1;

    return jsonb_build_object(
      'decision', 'replay',
      'message', 'QR ja utilizado.',
      'appointment_id', v_appointment.id,
      'usage_record_id', v_usage_id,
      'member_name', v_member_name,
      'holder_name', v_holder_name,
      'beneficiary_type', v_beneficiary_type,
      'holder_user_id', v_appointment.holder_user_id
    );
  end if;

  if v_appointment.status <> 'agendado' then
    return jsonb_build_object(
      'decision', 'refused',
      'message', 'Agendamento nao esta disponivel para validacao.',
      'appointment_id', v_appointment.id,
      'member_name', v_member_name,
      'holder_name', v_holder_name,
      'beneficiary_type', v_beneficiary_type,
      'holder_user_id', v_appointment.holder_user_id
    );
  end if;

  if v_appointment.scheduled_at < now() - interval '1 day' then
    update public.dependent_appointments
       set status = 'expirado', updated_at = now()
     where id = v_appointment.id;

    return jsonb_build_object(
      'decision', 'expired_appointment',
      'message', 'Agendamento expirado.',
      'appointment_id', v_appointment.id,
      'member_name', v_member_name,
      'holder_name', v_holder_name,
      'beneficiary_type', v_beneficiary_type,
      'holder_user_id', v_appointment.holder_user_id
    );
  end if;

  if v_appointment.beneficiary_type = 'dependent' then
    if not v_dependent_found or v_dependent.status <> 'active' then
      return jsonb_build_object(
        'decision', 'inactive_dependent',
        'message', 'Dependente inativo.',
        'appointment_id', v_appointment.id,
        'member_name', v_member_name,
        'holder_name', v_holder_name,
        'beneficiary_type', v_beneficiary_type,
        'holder_user_id', v_appointment.holder_user_id
      );
    end if;
  end if;

  select *
    into v_subscription
    from public.subscriptions
   where user_id = v_appointment.holder_user_id
     and is_current = true
     and cancelled_at is null
   limit 1;

  if not found then
    return jsonb_build_object(
      'decision', 'overdue_holder',
      'message', 'Titular sem assinatura ativa.',
      'appointment_id', v_appointment.id,
      'member_name', v_member_name,
      'holder_name', v_holder_name,
      'beneficiary_type', v_beneficiary_type,
      'holder_user_id', v_appointment.holder_user_id
    );
  end if;

  v_cycle_reference := to_char(v_subscription.activation_date::date, 'YYYY-MM-DD');

  select coalesce(value::int, 1)
    into v_limit
    from public.clinic_settings
   where key = 'monthly_uses_per_dependent';

  v_limit := coalesce(v_limit, 1);

  select count(*)
    into v_used_count
    from public.usage_records
   where holder_user_id = v_appointment.holder_user_id
     and beneficiary_type = v_appointment.beneficiary_type
     and beneficiary_id is not distinct from v_appointment.beneficiary_id
     and cycle_reference = v_cycle_reference;

  if v_used_count >= v_limit then
    return jsonb_build_object(
      'decision', 'quota_exhausted',
      'message', 'Cota esgotada para este ciclo.',
      'appointment_id', v_appointment.id,
      'remaining_uses', 0,
      'member_name', v_member_name,
      'holder_name', v_holder_name,
      'beneficiary_type', v_beneficiary_type,
      'holder_user_id', v_appointment.holder_user_id,
      'plan_level', v_subscription.plan_level_status::text
    );
  end if;

  insert into public.usage_records (
    appointment_id,
    holder_user_id,
    beneficiary_type,
    beneficiary_id,
    cycle_reference
  )
  values (
    v_appointment.id,
    v_appointment.holder_user_id,
    v_appointment.beneficiary_type,
    v_appointment.beneficiary_id,
    v_cycle_reference
  )
  returning id into v_usage_id;

  update public.dependent_appointments
     set status = 'utilizado',
         establishment_id = coalesce(p_establishment_id, establishment_id),
         updated_at = now()
   where id = v_appointment.id;

  select discount_percentage
    into v_discount
    from public.badges
   where level_name::text = v_subscription.plan_level_status::text
   limit 1;

  v_discount := coalesce(v_discount, 0);

  return jsonb_build_object(
    'decision', 'approved',
    'message', 'Uso validado.',
    'appointment_id', v_appointment.id,
    'usage_record_id', v_usage_id,
    'remaining_uses', greatest(v_limit - v_used_count - 1, 0),
    'plan_level', v_subscription.plan_level_status::text,
    'discount_percentage', v_discount,
    'holder_user_id', v_appointment.holder_user_id,
    'subscription_id', v_subscription.id,
    'member_name', v_member_name,
    'holder_name', v_holder_name,
    'beneficiary_type', v_beneficiary_type
  );
end;
$$;
