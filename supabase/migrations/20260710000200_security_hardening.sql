-- Security hardening: authorization must come from auth.uid(), never from
-- caller-supplied identity fields.

-- QR validation is an operator-only operation. The actor argument is retained
-- for API compatibility, but it must match the authenticated principal.
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
BEGIN
  IF auth.uid() IS NULL OR p_actor_user_id <> auth.uid()
     OR NOT public.is_admin() THEN
    RETURN jsonb_build_object('decision', 'refused',
      'message', 'Operação não autorizada.');
  END IF;

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

  IF NOT ((v_sub.status = 'active' AND v_sub.payment_access_status = 'allowed')
       OR (v_sub.status = 'payment_pending'
           AND v_sub.payment_access_status IN ('allowed', 'warning_pending'))
       OR (v_sub.status = 'cancelled'
           AND v_sub.current_period_end >= now())) THEN
    RETURN jsonb_build_object('decision', 'overdue_holder',
      'message', 'Assinatura bloqueada.', 'member_name', v_member_name,
      'plan_level', v_sub.plan_level_status::text);
  END IF;

  SELECT discount_percentage INTO v_discount FROM public.badges
   WHERE level_name::text = v_sub.plan_level_status::text LIMIT 1;

  RETURN jsonb_build_object('decision', 'approved', 'member_name', v_member_name,
    'plan_level', v_sub.plan_level_status::text,
    'discount_percentage', coalesce(v_discount, 0),
    'subscription_id', v_sub.id, 'holder_user_id', p_user_id);
END;
$$;

-- Rename the old atomic implementation once, retaining it as an internal
-- helper. The public function below becomes the authorization wrapper.
DO $$
BEGIN
  IF to_regprocedure('public.validate_dependent_qr_authorized(text,uuid,uuid)') IS NULL
     AND to_regprocedure('public.validate_dependent_qr(text,uuid,uuid)') IS NOT NULL THEN
    ALTER FUNCTION public.validate_dependent_qr(text, uuid, uuid)
      RENAME TO validate_dependent_qr_authorized;
  END IF;
END $$;

REVOKE ALL ON FUNCTION public.validate_dependent_qr_authorized(text, uuid, uuid)
  FROM PUBLIC;

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
     OR NOT (public.is_admin() OR public.is_parceiro()) THEN
    RETURN jsonb_build_object('decision', 'refused',
      'message', 'Operação não autorizada.');
  END IF;

  -- Keep the existing atomic implementation in one place while enforcing the
  -- principal check above. The appointment must also exist before proceeding.
  SELECT * INTO v_appointment FROM public.dependent_appointments
   WHERE qr_token = p_qr_token LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('decision', 'invalid_token', 'message', 'QR inválido.');
  END IF;

  -- The full validation body is intentionally delegated to the existing
  -- implementation through an internal helper created below.
  RETURN public.validate_dependent_qr_authorized(
    p_qr_token, p_actor_user_id, p_establishment_id);
END;
$$;

-- Never expose the QR signing secret to ordinary clients.
DROP POLICY IF EXISTS "Anyone authenticated can read clinic_settings"
  ON public.clinic_settings;
CREATE POLICY "Authenticated users can read public clinic settings"
  ON public.clinic_settings FOR SELECT TO authenticated
  USING (key <> 'dependents_qr_signing_secret');

DROP POLICY IF EXISTS "Only admins can insert clinic_settings" ON public.clinic_settings;
CREATE POLICY "Admins can insert public clinic settings"
  ON public.clinic_settings FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() AND key <> 'dependents_qr_signing_secret');
DROP POLICY IF EXISTS "Only admins can update clinic_settings" ON public.clinic_settings;
CREATE POLICY "Admins can update public clinic settings"
  ON public.clinic_settings FOR UPDATE TO authenticated
  USING (public.is_admin() AND key <> 'dependents_qr_signing_secret')
  WITH CHECK (public.is_admin() AND key <> 'dependents_qr_signing_secret');
DROP POLICY IF EXISTS "Only admins can delete clinic_settings" ON public.clinic_settings;
CREATE POLICY "Admins can delete public clinic settings"
  ON public.clinic_settings FOR DELETE TO authenticated
  USING (public.is_admin() AND key <> 'dependents_qr_signing_secret');

-- Payment intent fields are server-owned after creation. Users may only create
-- a pending intent for themselves; amount and cents are normalized from plans.
DROP POLICY IF EXISTS "Users can update own pending payment intents"
  ON public.payment_intents;

CREATE OR REPLACE FUNCTION public.normalize_payment_intent()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public AS $$
DECLARE v_price numeric(10,2);
BEGIN
  IF NEW.user_id <> auth.uid() AND auth.role() <> 'service_role' THEN
    RAISE EXCEPTION 'payment intent user mismatch';
  END IF;
  SELECT price INTO v_price FROM public.plans
   WHERE id = NEW.plan_id AND is_active = true;
  IF v_price IS NULL THEN RAISE EXCEPTION 'invalid or inactive plan'; END IF;
  IF TG_OP = 'INSERT' THEN
    NEW.provider := 'infinitypay';
    NEW.status := 'pending';
    NEW.amount := v_price;
    NEW.amount_cents := round(v_price * 100)::integer;
    NEW.currency := 'BRL';
  ELSIF auth.role() <> 'service_role' THEN
    IF NEW.user_id IS DISTINCT FROM OLD.user_id
       OR NEW.plan_id IS DISTINCT FROM OLD.plan_id
       OR NEW.amount IS DISTINCT FROM OLD.amount
       OR NEW.amount_cents IS DISTINCT FROM OLD.amount_cents
       OR NEW.status IS DISTINCT FROM OLD.status
       OR NEW.subscription_id IS DISTINCT FROM OLD.subscription_id
       OR NEW.order_nsu IS DISTINCT FROM OLD.order_nsu THEN
      RAISE EXCEPTION 'payment intent fields are server owned';
    END IF;
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS normalize_payment_intent ON public.payment_intents;
CREATE TRIGGER normalize_payment_intent BEFORE INSERT OR UPDATE
  ON public.payment_intents FOR EACH ROW EXECUTE FUNCTION public.normalize_payment_intent();

-- Users cannot forge validated consultations or their financial fields.
CREATE OR REPLACE FUNCTION public.guard_user_consultation()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public AS $$
BEGIN
  IF auth.role() = 'authenticated' AND NOT public.is_admin() THEN
    NEW.user_id := auth.uid();
    IF TG_OP = 'INSERT' THEN NEW.status := 'agendada'; END IF;
    NEW.validated_by := NULL; NEW.validated_at := NULL;
    NEW.original_value := NULL; NEW.discount_percentage := NULL;
    NEW.discount_amount := NULL; NEW.final_value := NULL;
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS guard_user_consultation ON public.consultations;
CREATE TRIGGER guard_user_consultation BEFORE INSERT OR UPDATE
  ON public.consultations FOR EACH ROW EXECUTE FUNCTION public.guard_user_consultation();

REVOKE ALL ON FUNCTION public.validate_member_qr(uuid, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.validate_member_qr(uuid, uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.validate_dependent_qr(text, uuid, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.validate_dependent_qr(text, uuid, uuid) TO authenticated;
