-- Preço, patente e cupom são decisão do financeiro.
-- Recepção continua lendo ( balcão / aplicar cupom ), mas não grava pela API.

DROP POLICY IF EXISTS "Admins can manage plans" ON public.plans;
DROP POLICY IF EXISTS "Admins can view all plans" ON public.plans;
CREATE POLICY "Admins can view all plans"
  ON public.plans FOR SELECT
  TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS "Financeiro can manage plans" ON public.plans;
CREATE POLICY "Financeiro can manage plans"
  ON public.plans FOR ALL
  TO authenticated
  USING (public.is_financeiro())
  WITH CHECK (public.is_financeiro());

DROP POLICY IF EXISTS "Admins can manage plan benefits" ON public.plan_benefits;
DROP POLICY IF EXISTS "Admins can view plan benefits" ON public.plan_benefits;
CREATE POLICY "Admins can view plan benefits extra"
  ON public.plan_benefits FOR SELECT
  TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS "Financeiro can manage plan benefits" ON public.plan_benefits;
CREATE POLICY "Financeiro can manage plan benefits"
  ON public.plan_benefits FOR ALL
  TO authenticated
  USING (public.is_financeiro())
  WITH CHECK (public.is_financeiro());

DROP POLICY IF EXISTS "Admins can manage badges" ON public.badges;
DROP POLICY IF EXISTS "Admins can view badges extra" ON public.badges;
CREATE POLICY "Admins can view badges extra"
  ON public.badges FOR SELECT
  TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS "Financeiro can manage badges" ON public.badges;
CREATE POLICY "Financeiro can manage badges"
  ON public.badges FOR ALL
  TO authenticated
  USING (public.is_financeiro())
  WITH CHECK (public.is_financeiro());

DROP POLICY IF EXISTS "Admins can manage coupons" ON public.coupons;
DROP POLICY IF EXISTS "Admins can view coupons" ON public.coupons;
CREATE POLICY "Admins can view coupons"
  ON public.coupons FOR SELECT
  TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS "Financeiro can manage coupons" ON public.coupons;
CREATE POLICY "Financeiro can manage coupons"
  ON public.coupons FOR ALL
  TO authenticated
  USING (public.is_financeiro())
  WITH CHECK (public.is_financeiro());
