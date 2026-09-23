begin;

-- Regression guards: the mobile role must not be able to mutate financial
-- source-of-truth tables or provider identifiers directly.
set local role authenticated;

do $$
begin
  if has_table_privilege('authenticated', 'public.subscriptions', 'INSERT')
     or has_table_privilege('authenticated', 'public.subscriptions', 'UPDATE')
     or has_table_privilege('authenticated', 'public.subscriptions', 'DELETE') then
    raise exception 'authenticated can mutate subscriptions directly';
  end if;
  if has_table_privilege('authenticated', 'public.mercadopago_webhook_events', 'SELECT,INSERT,UPDATE,DELETE') then
    raise exception 'authenticated can access Mercado Pago webhook events';
  end if;
  if has_table_privilege('authenticated', 'public.mercadopago_price_change_jobs', 'INSERT,UPDATE,DELETE') then
    raise exception 'authenticated can mutate Mercado Pago price jobs';
  end if;
  if has_table_privilege('authenticated', 'public.mercadopago_authorized_payments', 'INSERT,UPDATE,DELETE') then
    raise exception 'authenticated can mutate authorized payments';
  end if;
end $$;

rollback;
