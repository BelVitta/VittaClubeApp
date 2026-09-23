-- Regression checks for partner validation sessions.
-- Run in a Supabase database after migrations have been applied.

begin;

do $$
begin
  if has_table_privilege(
       'authenticated',
       'public.partner_validation_sessions',
       'SELECT,INSERT,UPDATE,DELETE'
     ) then
    raise exception 'authenticated must not access validation sessions directly';
  end if;

  if has_function_privilege(
       'anon',
       'public.confirm_partner_validation(uuid,numeric)',
       'EXECUTE'
     ) then
    raise exception 'anon must not confirm partner validations';
  end if;

  if to_regprocedure(
       'public.confirm_partner_validation(uuid, text, uuid, numeric, text)'
     ) is not null then
    raise exception 'legacy client-controlled confirmation signature still exists';
  end if;
end $$;

-- Runtime cases to exercise with seeded users:
-- 1. a partner scan creates one session that expires after five minutes;
-- 2. confirmation succeeds only for the same partner account;
-- 3. a second confirmation of the same session is rejected;
-- 4. changing the holder/dependent/plan in the client is impossible because
--    those fields are not accepted by the RPC;
-- 5. an expired, blocked or detached dependent session is rejected.

rollback;

