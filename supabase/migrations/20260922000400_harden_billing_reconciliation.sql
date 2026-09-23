-- Durable leases let the reconciliation worker recover webhook events that
-- were claimed by a crashed invocation instead of leaving them in processing.

alter table public.mercadopago_webhook_events
  add column if not exists processing_started_at timestamptz,
  add column if not exists lease_until timestamptz;

create index if not exists mercadopago_webhook_events_lease_idx
  on public.mercadopago_webhook_events (processing_status, lease_until, received_at);

comment on column public.mercadopago_webhook_events.lease_until is
  'Worker lease. Events with an expired lease may be claimed again safely.';

