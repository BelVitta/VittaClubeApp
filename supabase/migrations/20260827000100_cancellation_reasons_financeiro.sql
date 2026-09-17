-- Motivos de cancelamento: CRUD só do financeiro.
-- Admin (recepção) pode ler para aplicar no fluxo de cancelamento.

DROP POLICY IF EXISTS "Admins can manage cancellation reasons"
  ON public.cancellation_reasons;

DROP POLICY IF EXISTS "Financeiro can manage cancellation reasons"
  ON public.cancellation_reasons;
CREATE POLICY "Financeiro can manage cancellation reasons"
  ON public.cancellation_reasons FOR ALL
  USING (public.is_financeiro())
  WITH CHECK (public.is_financeiro());

DROP POLICY IF EXISTS "Admins can view cancellation reasons"
  ON public.cancellation_reasons;
CREATE POLICY "Admins can view cancellation reasons"
  ON public.cancellation_reasons FOR SELECT
  USING (public.is_admin());
