-- Harden draw execution.
--
-- A draw must be executed by the server after re-checking eligibility.  The
-- previous function accepted a caller supplied seed and did not authenticate
-- the caller, which allowed an authenticated client to attempt to choose the
-- result directly.

-- Keep the old signature from being callable after clients are migrated.
drop function if exists public.execute_draw(uuid, text);

create or replace function public.execute_draw(p_draw_id uuid)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, extensions, public
as $$
declare
  v_actor_role public.user_role;
  v_draw public.draws;
  v_participant_ids uuid[];
  v_participant_count integer;
  v_winner_index integer;
  v_winner_id uuid;
  v_seed text;
  v_seed_hash text;
  v_participant_hash text;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  select p.role
    into v_actor_role
    from public.profiles p
   where p.id = auth.uid();

  if v_actor_role is null
     or v_actor_role not in ('admin'::public.user_role, 'financeiro'::public.user_role) then
    raise exception 'Somente admin ou financeiro pode executar sorteios';
  end if;

  -- The row lock makes concurrent execution deterministic: the second caller
  -- waits, then sees the already completed status and is rejected.
  select d.*
    into v_draw
    from public.draws d
   where d.id = p_draw_id
   for update;

  if not found then
    raise exception 'Sorteio não encontrado';
  end if;

  if v_draw.status <> 'inscricoes_encerradas'::public.draw_status then
    raise exception 'Sorteio não está pronto para execução';
  end if;

  -- Revalidate access and badge at execution time. A participant who became
  -- blocked or whose paid period expired no longer enters the snapshot.
  select coalesce(array_agg(dp.user_id order by dp.user_id), '{}'::uuid[])
    into v_participant_ids
    from public.draw_participants dp
    join public.subscriptions s
      on s.user_id = dp.user_id
     and s.is_current = true
     and s.current_period_end is not null
     and s.current_period_end > now()
     and (
       (s.status = 'active'::public.subscription_status
        and s.payment_access_status = 'allowed'::public.payment_access_status)
       or (s.status = 'payment_pending'::public.subscription_status
           and s.payment_access_status in (
             'allowed'::public.payment_access_status,
             'warning_pending'::public.payment_access_status
           ))
       or (s.status = 'cancelled'::public.subscription_status
           and s.payment_access_status = 'allowed'::public.payment_access_status)
     )
   where dp.draw_id = p_draw_id
     and (
       coalesce(array_length(v_draw.eligible_plan_levels, 1), 0) = 0
       or s.badge_level = any(v_draw.eligible_plan_levels)
     );

  v_participant_count := coalesce(array_length(v_participant_ids, 1), 0);
  if v_participant_count = 0 then
    raise exception 'Nenhum participante elegível';
  end if;

  -- The seed is generated only inside Postgres and is never accepted from the
  -- mobile client. The hash is retained for the existing audit fields.
  v_seed := encode(extensions.gen_random_bytes(32), 'hex');
  v_seed_hash := encode(extensions.digest(v_seed, 'sha256'), 'hex');
  v_participant_hash := encode(
    extensions.digest(array_to_string(v_participant_ids, ','), 'sha256'),
    'hex'
  );

  -- Convert the first 32 bits to a non-negative bigint before modulo, avoiding
  -- abs(integer) overflow for the minimum signed integer.
  v_winner_index := mod(
    (('x' || substring(v_seed_hash, 1, 8))::bit(32)::bigint + 2147483648),
    v_participant_count
  )::integer;
  v_winner_id := v_participant_ids[v_winner_index + 1];

  -- This transaction-local marker allows the trigger below to distinguish the
  -- protected execution update from ordinary admin edits to a draw.
  perform set_config('vitta.draw_execution', 'true', true);

  update public.draws
     set status = 'realizado'::public.draw_status,
         winner_id = v_winner_id,
         draw_seed_hash = v_seed_hash,
         participant_list_hash = v_participant_hash,
         executed_at = now(),
         winner_index = v_winner_index,
         participant_count = v_participant_count,
         updated_at = now()
   where id = p_draw_id;

  insert into public.audit_log (
    table_name,
    record_id,
    action,
    new_data,
    performed_by
  ) values (
    'draws',
    p_draw_id,
    'UPDATE',
    jsonb_build_object(
      'event', 'draw_executed',
      'eligible_participant_count', v_participant_count,
      'winner_id', v_winner_id,
      'winner_index', v_winner_index,
      'participant_list_hash', v_participant_hash,
      'draw_seed_hash', v_seed_hash
    ),
    auth.uid()
  );

  return v_winner_id;
end;
$$;

revoke all on function public.execute_draw(uuid) from public, anon;
grant execute on function public.execute_draw(uuid) to authenticated;

-- Winner and transparency fields are server-owned. Admins may still edit the
-- descriptive/scheduling fields through the existing draws policy.
create or replace function public.prevent_direct_draw_result_update()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, extensions, public
as $$
begin
  if current_setting('vitta.draw_execution', true) is distinct from 'true'
     and (
       new.status = 'realizado'::public.draw_status
       or (old.status = 'realizado'::public.draw_status
           and new.status is distinct from old.status)
       or new.winner_id is distinct from old.winner_id
       or new.winner_index is distinct from old.winner_index
       or new.draw_seed_hash is distinct from old.draw_seed_hash
       or new.participant_list_hash is distinct from old.participant_list_hash
       or new.executed_at is distinct from old.executed_at
     ) then
    raise exception 'Resultado do sorteio só pode ser definido pelo servidor';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_direct_draw_result_update on public.draws;
create trigger trg_prevent_direct_draw_result_update
before update on public.draws
for each row execute function public.prevent_direct_draw_result_update();
