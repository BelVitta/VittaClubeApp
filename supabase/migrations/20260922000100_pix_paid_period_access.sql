-- Access to paid benefits must always be backed by a non-expired period.
-- A provider authorization or a pending retry alone is not payment.

create or replace function public.holder_can_use_qr(p_sub public.subscriptions)
returns boolean
language sql
stable
set search_path = pg_catalog, public
as $$
  select
    p_sub.current_period_end is not null
    and p_sub.current_period_end > now()
    and (
      (p_sub.status = 'active' and p_sub.payment_access_status = 'allowed')
      or (p_sub.status = 'payment_pending'
          and p_sub.payment_access_status in ('allowed', 'warning_pending'))
      or (p_sub.status = 'cancelled'
          and p_sub.payment_access_status = 'allowed')
    );
$$;

create or replace view public.current_user_payment_status as
select
  s.user_id,
  s.id as subscription_id,
  s.status as subscription_status,
  s.payment_access_status,
  public.holder_can_use_qr(s) as can_access,
  public.holder_can_use_qr(s) as can_use_qr,
  s.status in ('blocked', 'expired', 'rejected') as restore_required,
  s.payment_link_url,
  s.current_period_end,
  s.next_billing_date
from public.subscriptions s
where s.is_current = true;

comment on function public.holder_can_use_qr(public.subscriptions) is
  'Only a non-expired paid period grants benefits; authorization alone is insufficient.';
