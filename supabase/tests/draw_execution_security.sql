-- Regression checks for the hardened draw execution RPC.
-- Run in a Supabase database after migrations have been applied.

begin;

do $$
begin
  if has_function_privilege('anon', 'public.execute_draw(uuid)', 'EXECUTE') then
    raise exception 'anon must not execute public.execute_draw(uuid)';
  end if;
  if not has_function_privilege('authenticated', 'public.execute_draw(uuid)', 'EXECUTE') then
    raise exception 'authenticated must be able to call the guarded RPC';
  end if;
  if to_regprocedure('public.execute_draw(uuid, text)') is not null then
    raise exception 'legacy seed-accepting execute_draw overload still exists';
  end if;
end $$;

-- Runtime cases to exercise with seeded users:
-- 1. anon and a role=user call must fail with authorization error;
-- 2. admin/financeiro call on an inscricoes_encerradas draw succeeds;
-- 3. two concurrent calls yield one winner and the second is rejected;
-- 4. direct UPDATE of winner/status/audit fields is rejected by the trigger;
-- 5. an expired or blocked subscription is excluded from the snapshot.

rollback;

