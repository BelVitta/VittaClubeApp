-- Recepção (role admin) não gerencia acordo comercial nem inventa validação.
-- Parceiro só honra o %; insert de validação só via RPC SECURITY DEFINER.
-- Pagamentos: recepção lê; financeiro escreve; webhooks usam service_role.

-- ── partners: recepção só lê; financeiro gerencia
DROP POLICY IF EXISTS "Admins can manage partners" ON public.partners;
DROP POLICY IF EXISTS "Admins can view partners" ON public.partners;
CREATE POLICY "Admins can view partners"
  ON public.partners FOR SELECT
  TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS "Financeiro can manage partners" ON public.partners;
CREATE POLICY "Financeiro can manage partners"
  ON public.partners FOR ALL
  TO authenticated
  USING (public.is_financeiro())
  WITH CHECK (public.is_financeiro());

-- Parceiro não desativa o lab nem muda categoria/vínculo/% (já travado).
CREATE OR REPLACE FUNCTION public.partners_lock_commercial_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NOT public.is_financeiro() THEN
    IF NEW.discount_percentage IS DISTINCT FROM OLD.discount_percentage THEN
      RAISE EXCEPTION 'Apenas o financeiro pode alterar o percentual do acordo.';
    END IF;
    IF NEW.is_active IS DISTINCT FROM OLD.is_active
       OR NEW.category IS DISTINCT FROM OLD.category
       OR NEW.profile_id IS DISTINCT FROM OLD.profile_id
       OR NEW.code IS DISTINCT FROM OLD.code THEN
      RAISE EXCEPTION 'Apenas o financeiro pode alterar status, categoria, vínculo ou código do parceiro.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_partners_lock_discount_percentage ON public.partners;
DROP TRIGGER IF EXISTS trg_partners_lock_commercial_fields ON public.partners;
CREATE TRIGGER trg_partners_lock_commercial_fields
  BEFORE UPDATE ON public.partners
  FOR EACH ROW
  EXECUTE FUNCTION public.partners_lock_commercial_fields();

-- ── partner_services: recepção lê; dono e financeiro gerenciam
DROP POLICY IF EXISTS "Admins can manage partner services" ON public.partner_services;
DROP POLICY IF EXISTS "Admins can view partner services" ON public.partner_services;
CREATE POLICY "Admins can view partner services"
  ON public.partner_services FOR SELECT
  TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS "Financeiro can manage partner services" ON public.partner_services;
CREATE POLICY "Financeiro can manage partner services"
  ON public.partner_services FOR ALL
  TO authenticated
  USING (public.is_financeiro())
  WITH CHECK (public.is_financeiro());

-- ── partner_validations: sem INSERT pelo cliente; só RPC
DROP POLICY IF EXISTS "Parceiros can insert own validations" ON public.partner_validations;
DROP POLICY IF EXISTS "Admins can manage partner validations" ON public.partner_validations;

DROP POLICY IF EXISTS "Admins can view partner validations" ON public.partner_validations;
CREATE POLICY "Admins can view partner validations"
  ON public.partner_validations FOR SELECT
  TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS "Financeiro can view partner validations" ON public.partner_validations;
CREATE POLICY "Financeiro can view partner validations"
  ON public.partner_validations FOR SELECT
  TO authenticated
  USING (public.is_financeiro());

REVOKE INSERT, UPDATE, DELETE ON public.partner_validations FROM authenticated, anon, PUBLIC;
GRANT SELECT ON public.partner_validations TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.partner_validations TO service_role;

-- ── payments: recepção só lê; financeiro gerencia
DROP POLICY IF EXISTS "Admins can manage all payments" ON public.payments;
DROP POLICY IF EXISTS "Admins can view all payments" ON public.payments;
CREATE POLICY "Admins can view all payments"
  ON public.payments FOR SELECT
  TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS "Financeiro can view all payments" ON public.payments;
DROP POLICY IF EXISTS "Financeiro can manage all payments" ON public.payments;
CREATE POLICY "Financeiro can manage all payments"
  ON public.payments FOR ALL
  TO authenticated
  USING (public.is_financeiro())
  WITH CHECK (public.is_financeiro());

-- ── QR de agendamento de clínica: não é papel do lab
CREATE OR REPLACE FUNCTION public.validate_dependent_qr(
  p_qr_token text,
  p_actor_user_id uuid,
  p_establishment_id uuid DEFAULT null
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_appointment public.dependent_appointments%rowtype;
BEGIN
  IF auth.uid() IS NULL OR p_actor_user_id <> auth.uid()
     OR NOT public.is_admin() THEN
    RETURN jsonb_build_object('decision', 'refused',
      'message', 'Operação não autorizada.');
  END IF;

  SELECT * INTO v_appointment FROM public.dependent_appointments
   WHERE qr_token = p_qr_token LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('decision', 'invalid_token', 'message', 'QR inválido.');
  END IF;

  RETURN public.validate_dependent_qr_authorized(
    p_qr_token, p_actor_user_id, p_establishment_id);
END;
$$;
