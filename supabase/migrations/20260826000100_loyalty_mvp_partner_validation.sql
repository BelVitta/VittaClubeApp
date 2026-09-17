-- Loyalty MVP: partner agreement %, partner-device validation,
-- and card payloads for holder + dependent.
-- Requires 20260826000050_create_partners_tables (public.partners).

-- ── 1. partners.discount_percentage (live agreement, financeiro-owned)
ALTER TABLE public.partners
  ADD COLUMN IF NOT EXISTS discount_percentage NUMERIC(5,2) NOT NULL DEFAULT 0
  CONSTRAINT partners_discount_percentage_range
    CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

COMMENT ON COLUMN public.partners.discount_percentage IS
  'Percentual vivo do acordo comercial. Só o financeiro publica/edita.';

ALTER TABLE public.partner_applications
  ADD COLUMN IF NOT EXISTS proposed_discount_percentage NUMERIC(5,2)
  CONSTRAINT partner_applications_proposed_discount_range
    CHECK (
      proposed_discount_percentage IS NULL
      OR (proposed_discount_percentage >= 0 AND proposed_discount_percentage <= 100)
    );

-- ── 2. partner_validations: savings + beneficiary
ALTER TABLE public.partner_validations
  ADD COLUMN IF NOT EXISTS discount_percentage NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS original_value NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS savings_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS beneficiary_type TEXT,
  ADD COLUMN IF NOT EXISTS dependent_id UUID REFERENCES public.dependents(id) ON DELETE SET NULL;

ALTER TABLE public.partner_validations
  ALTER COLUMN service_id DROP NOT NULL;

ALTER TABLE public.partner_validations
  ALTER COLUMN service_name SET DEFAULT 'Carteirinha Vita Clube';

-- ── 3. Lock live %: only financeiro may change it
CREATE OR REPLACE FUNCTION public.partners_lock_discount_percentage()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.discount_percentage IS DISTINCT FROM OLD.discount_percentage
     AND NOT public.is_financeiro() THEN
    RAISE EXCEPTION 'Apenas o financeiro pode alterar o percentual do acordo.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_partners_lock_discount_percentage ON public.partners;
CREATE TRIGGER trg_partners_lock_discount_percentage
  BEFORE UPDATE ON public.partners
  FOR EACH ROW
  EXECUTE FUNCTION public.partners_lock_discount_percentage();

-- Financeiro full manage on partners (admin policy already exists via is_admin)
DROP POLICY IF EXISTS "Financeiro can manage partners" ON public.partners;
CREATE POLICY "Financeiro can manage partners"
  ON public.partners FOR ALL
  USING (public.is_financeiro())
  WITH CHECK (public.is_financeiro());

DROP POLICY IF EXISTS "Users can view own partner validations" ON public.partner_validations;
CREATE POLICY "Users can view own partner validations"
  ON public.partner_validations FOR SELECT
  USING (user_id = auth.uid());

-- Partner may insert own validations (confirm on device)
DROP POLICY IF EXISTS "Parceiros can insert own validations" ON public.partner_validations;
CREATE POLICY "Parceiros can insert own validations"
  ON public.partner_validations FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.partners
      WHERE partners.id = partner_validations.partner_id
        AND partners.profile_id = auth.uid()
    )
  );

-- ── 4. Shared helper: can this holder use the card?
CREATE OR REPLACE FUNCTION public.holder_can_use_qr(p_sub public.subscriptions)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT
    (p_sub.status = 'active' AND p_sub.payment_access_status = 'allowed')
    OR (p_sub.status = 'payment_pending'
        AND p_sub.payment_access_status IN ('allowed', 'warning_pending'))
    OR (p_sub.status = 'cancelled'
        AND p_sub.current_period_end IS NOT NULL
        AND p_sub.current_period_end >= now());
$$;

CREATE OR REPLACE FUNCTION public.actor_can_validate_card()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT public.is_admin() OR public.is_financeiro() OR public.is_parceiro();
$$;

-- ── 5. validate_member_qr: admin | financeiro | parceiro
--     Parceiro receives AGREEMENT percent, clinic receives BADGE percent.
CREATE OR REPLACE FUNCTION public.validate_member_qr(
  p_user_id uuid,
  p_actor_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_member_name text;
  v_sub public.subscriptions%rowtype;
  v_discount numeric(5,2) := 0;
  v_partner public.partners%rowtype;
  v_is_partner boolean := false;
  v_message text;
BEGIN
  IF auth.uid() IS NULL OR p_actor_user_id <> auth.uid()
     OR NOT public.actor_can_validate_card() THEN
    RETURN jsonb_build_object('decision', 'refused',
      'message', 'Operação não autorizada.');
  END IF;

  v_is_partner := public.is_parceiro();

  SELECT name INTO v_member_name FROM public.profiles WHERE id = p_user_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('decision', 'invalid_token',
      'message', 'QR inválido: membro não encontrado.');
  END IF;

  SELECT * INTO v_sub FROM public.subscriptions
   WHERE user_id = p_user_id AND is_current = true LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('decision', 'refused',
      'message', 'Membro sem assinatura ativa.', 'member_name', v_member_name);
  END IF;

  IF NOT public.holder_can_use_qr(v_sub) THEN
    RETURN jsonb_build_object('decision', 'overdue_holder',
      'message', 'Assinatura bloqueada ou com pagamento pendente. Membro deve regularizar.',
      'member_name', v_member_name,
      'plan_level', v_sub.plan_level_status::text,
      'holder_user_id', p_user_id,
      'beneficiary_type', 'holder');
  END IF;

  IF v_is_partner THEN
    SELECT * INTO v_partner FROM public.partners
     WHERE profile_id = auth.uid() AND is_active = true
     LIMIT 1;
    IF NOT FOUND THEN
      RETURN jsonb_build_object('decision', 'refused',
        'message', 'Estabelecimento parceiro inativo ou não encontrado.');
    END IF;
    v_discount := coalesce(v_partner.discount_percentage, 0);
    v_message := format('Membro ativo. Aplique %s%% (acordo).', v_discount);
  ELSE
    SELECT discount_percentage INTO v_discount FROM public.badges
     WHERE level_name::text = v_sub.plan_level_status::text LIMIT 1;
    v_discount := coalesce(v_discount, 0);
    v_message := format('Membro ativo. Desconto de %s%% aplicável.', v_discount);
  END IF;

  RETURN jsonb_build_object(
    'decision', 'approved',
    'message', v_message,
    'member_name', v_member_name,
    'plan_level', v_sub.plan_level_status::text,
    'discount_percentage', v_discount,
    'discount_source', CASE WHEN v_is_partner THEN 'agreement' ELSE 'badge' END,
    'subscription_id', v_sub.id,
    'holder_user_id', p_user_id,
    'beneficiary_type', 'holder',
    'partner_id', CASE WHEN v_is_partner THEN v_partner.id ELSE NULL END
  );
END;
$$;

-- ── 6. validate_member_code: same actor set
CREATE OR REPLACE FUNCTION public.validate_member_code(
  p_member_code text,
  p_actor_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_code text;
  v_user_id uuid;
BEGIN
  IF auth.uid() IS NULL OR p_actor_user_id <> auth.uid()
     OR NOT public.actor_can_validate_card() THEN
    RETURN jsonb_build_object(
      'decision', 'refused',
      'message', 'Operação não autorizada.'
    );
  END IF;

  v_code := regexp_replace(coalesce(p_member_code, ''), '\D', '', 'g');
  IF length(v_code) <> 8 THEN
    RETURN jsonb_build_object(
      'decision', 'invalid_token',
      'message', 'Código inválido. Use os 8 dígitos da carteirinha.'
    );
  END IF;

  SELECT id INTO v_user_id
    FROM public.profiles
   WHERE member_code = v_code
   LIMIT 1;

  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'decision', 'invalid_token',
      'message', 'Código não encontrado.'
    );
  END IF;

  RETURN public.validate_member_qr(v_user_id, p_actor_user_id);
END;
$$;

-- ── 7. Dependent on the card (payload vc:dep:<uuid>)
CREATE OR REPLACE FUNCTION public.validate_dependent_card(
  p_dependent_id uuid,
  p_actor_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_dep public.dependents%rowtype;
  v_holder_name text;
  v_sub public.subscriptions%rowtype;
  v_discount numeric(5,2) := 0;
  v_partner public.partners%rowtype;
  v_is_partner boolean := false;
  v_message text;
  v_cpf_masked text;
BEGIN
  IF auth.uid() IS NULL OR p_actor_user_id <> auth.uid()
     OR NOT public.actor_can_validate_card() THEN
    RETURN jsonb_build_object('decision', 'refused',
      'message', 'Operação não autorizada.');
  END IF;

  v_is_partner := public.is_parceiro();

  SELECT * INTO v_dep FROM public.dependents WHERE id = p_dependent_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('decision', 'invalid_token',
      'message', 'QR inválido: dependente não encontrado.');
  END IF;

  IF v_dep.status IS DISTINCT FROM 'active' THEN
    RETURN jsonb_build_object(
      'decision', 'inactive_dependent',
      'message', 'Dependente não liberado. Aprovação presencial na recepção Vitta é necessária.',
      'member_name', v_dep.name,
      'holder_user_id', v_dep.holder_user_id,
      'beneficiary_type', 'dependent',
      'dependent_id', v_dep.id
    );
  END IF;

  SELECT name INTO v_holder_name FROM public.profiles WHERE id = v_dep.holder_user_id;

  SELECT * INTO v_sub FROM public.subscriptions
   WHERE user_id = v_dep.holder_user_id AND is_current = true LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'decision', 'refused',
      'message', 'Titular sem assinatura ativa.',
      'member_name', v_dep.name,
      'holder_name', v_holder_name,
      'holder_user_id', v_dep.holder_user_id,
      'beneficiary_type', 'dependent'
    );
  END IF;

  IF NOT public.holder_can_use_qr(v_sub) THEN
    RETURN jsonb_build_object(
      'decision', 'overdue_holder',
      'message', 'Assinatura do titular bloqueada. Regularize para usar o benefício.',
      'member_name', v_dep.name,
      'holder_name', v_holder_name,
      'plan_level', v_sub.plan_level_status::text,
      'holder_user_id', v_dep.holder_user_id,
      'beneficiary_type', 'dependent',
      'dependent_id', v_dep.id
    );
  END IF;

  IF length(regexp_replace(coalesce(v_dep.cpf, ''), '\D', '', 'g')) >= 2 THEN
    v_cpf_masked := '***.***.***-' || right(regexp_replace(v_dep.cpf, '\D', '', 'g'), 2);
  END IF;

  IF v_is_partner THEN
    SELECT * INTO v_partner FROM public.partners
     WHERE profile_id = auth.uid() AND is_active = true
     LIMIT 1;
    IF NOT FOUND THEN
      RETURN jsonb_build_object('decision', 'refused',
        'message', 'Estabelecimento parceiro inativo ou não encontrado.');
    END IF;
    v_discount := coalesce(v_partner.discount_percentage, 0);
    v_message := format('Dependente ativo. Aplique %s%% (acordo).', v_discount);
  ELSE
    SELECT discount_percentage INTO v_discount FROM public.badges
     WHERE level_name::text = v_sub.plan_level_status::text LIMIT 1;
    v_discount := coalesce(v_discount, 0);
    v_message := format('Dependente ativo. Desconto de %s%% aplicável.', v_discount);
  END IF;

  RETURN jsonb_build_object(
    'decision', 'approved',
    'message', v_message,
    'member_name', v_dep.name,
    'holder_name', v_holder_name,
    'plan_level', v_sub.plan_level_status::text,
    'discount_percentage', v_discount,
    'discount_source', CASE WHEN v_is_partner THEN 'agreement' ELSE 'badge' END,
    'subscription_id', v_sub.id,
    'holder_user_id', v_dep.holder_user_id,
    'beneficiary_type', 'dependent',
    'dependent_id', v_dep.id,
    'cpf_masked', v_cpf_masked,
    'partner_id', CASE WHEN v_is_partner THEN v_partner.id ELSE NULL END
  );
END;
$$;

-- ── 8. Single payload entry: UUID | 8-digit code | vc:dep:<uuid>
CREATE OR REPLACE FUNCTION public.validate_loyalty_card(
  p_payload text,
  p_actor_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_raw text;
  v_digits text;
  v_dep_id uuid;
  v_user_id uuid;
BEGIN
  v_raw := btrim(coalesce(p_payload, ''));
  IF v_raw = '' THEN
    RETURN jsonb_build_object('decision', 'invalid_token', 'message', 'QR vazio.');
  END IF;

  IF left(v_raw, 7) = 'vc:dep:' THEN
    BEGIN
      v_dep_id := substr(v_raw, 8)::uuid;
    EXCEPTION WHEN OTHERS THEN
      RETURN jsonb_build_object('decision', 'invalid_token',
        'message', 'QR de dependente inválido.');
    END;
    RETURN public.validate_dependent_card(v_dep_id, p_actor_user_id);
  END IF;

  v_digits := regexp_replace(v_raw, '\D', '', 'g');
  IF length(v_digits) = 8 AND v_raw !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    RETURN public.validate_member_code(v_digits, p_actor_user_id);
  END IF;

  BEGIN
    v_user_id := v_raw::uuid;
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('decision', 'invalid_token',
      'message', 'QR inválido.');
  END;

  RETURN public.validate_member_qr(v_user_id, p_actor_user_id);
END;
$$;

-- ── 9. Partner confirms validation on their device
CREATE OR REPLACE FUNCTION public.confirm_partner_validation(
  p_holder_user_id uuid,
  p_member_name text,
  p_dependent_id uuid DEFAULT NULL,
  p_original_value numeric DEFAULT NULL,
  p_plan_level text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_partner public.partners%rowtype;
  v_pct numeric(5,2);
  v_savings numeric(10,2) := 0;
  v_id uuid;
  v_beneficiary text;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_parceiro() THEN
    RETURN jsonb_build_object('ok', false, 'message', 'Operação não autorizada.');
  END IF;

  SELECT * INTO v_partner FROM public.partners
   WHERE profile_id = auth.uid() AND is_active = true
   LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'message', 'Parceiro inativo.');
  END IF;

  v_pct := coalesce(v_partner.discount_percentage, 0);
  IF p_original_value IS NOT NULL AND p_original_value > 0 THEN
    v_savings := round(p_original_value * v_pct / 100.0, 2);
  END IF;

  v_beneficiary := CASE WHEN p_dependent_id IS NULL THEN 'holder' ELSE 'dependent' END;

  INSERT INTO public.partner_validations (
    partner_id, user_id, service_id, user_name, user_badge_level,
    discount_applied, service_name, discount_percentage, original_value,
    savings_amount, beneficiary_type, dependent_id
  ) VALUES (
    v_partner.id,
    p_holder_user_id,
    NULL,
    coalesce(nullif(btrim(p_member_name), ''), 'Membro'),
    coalesce(p_plan_level, 'bronze'),
    v_savings,
    'Carteirinha Vita Clube',
    v_pct,
    p_original_value,
    v_savings,
    v_beneficiary,
    p_dependent_id
  )
  RETURNING id INTO v_id;

  RETURN jsonb_build_object(
    'ok', true,
    'id', v_id,
    'discount_percentage', v_pct,
    'savings_amount', v_savings,
    'original_value', p_original_value
  );
END;
$$;

REVOKE ALL ON FUNCTION public.holder_can_use_qr(public.subscriptions) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.actor_can_validate_card() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.validate_dependent_card(uuid, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.validate_loyalty_card(text, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.confirm_partner_validation(uuid, text, uuid, numeric, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.partners_lock_discount_percentage() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.validate_dependent_card(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_loyalty_card(text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_partner_validation(uuid, text, uuid, numeric, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_member_qr(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_member_code(text, uuid) TO authenticated;
