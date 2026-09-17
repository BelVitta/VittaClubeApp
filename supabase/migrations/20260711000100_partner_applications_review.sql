-- Suporte a revisão (aprovar/rejeitar) de candidaturas de parceiro pelo
-- admin, mesmo padrão já usado em dependents (approved_by/rejection_reason).
alter table public.partner_applications
  add column if not exists reviewed_by uuid references public.profiles(id),
  add column if not exists rejection_reason text;
