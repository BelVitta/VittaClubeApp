-- Regression checks for billing idempotency and reconciliation infrastructure.
-- Run after migrations in a Supabase database.

begin;

do $$
begin
  if to_regclass('public.mercadopago_webhook_events') is null then
    raise exception 'Mercado Pago webhook queue is missing';
  end if;
  if not exists (
    select 1
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'mercadopago_webhook_events'
       and column_name = 'lease_until'
  ) then
    raise exception 'Webhook lease column is missing';
  end if;
end $$;

-- Runtime cases to exercise with provider fixtures:
-- 1. two workers claim an event: exactly one receives the lease;
-- 2. an expired lease is reclaimed;
-- 3. duplicate approved payment creates one provider_payment_id row;
-- 4. an older approved payment never shortens current_period_end;
-- 5. a missing webhook is recovered by remote subscription scanning;
-- 6. active/payment_pending periods are blocked after current_period_end.

rollback;
