-- Expire stale dependent appointments without quota side effects.
-- Intended to be called by pg_cron, Supabase scheduled job, or staging ops.

create or replace function public.expire_stale_dependent_appointments(
  p_reference_at timestamptz default now(),
  p_grace_period interval default interval '1 day'
)
returns integer
language plpgsql
security definer
as $$
declare
  v_expired_count integer;
begin
  update public.dependent_appointments
     set status = 'expirado',
         updated_at = now()
   where status = 'agendado'
     and scheduled_at < p_reference_at - p_grace_period;

  get diagnostics v_expired_count = row_count;
  return v_expired_count;
end;
$$;
