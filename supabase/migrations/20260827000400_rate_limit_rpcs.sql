-- Rate limit por usuário autenticado (auth.uid()).
-- Login/cadastro/reset continuam no Auth nativo do Supabase.
-- Webhooks (Woovi HMAC / InfinityPay) NÃO passam por aqui.

CREATE TABLE IF NOT EXISTS public.rate_limit_buckets (
  action text NOT NULL,
  subject uuid NOT NULL,
  window_start timestamptz NOT NULL,
  hit_count integer NOT NULL DEFAULT 0,
  PRIMARY KEY (action, subject, window_start)
);

ALTER TABLE public.rate_limit_buckets ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.rate_limit_buckets FROM PUBLIC, anon, authenticated;

COMMENT ON TABLE public.rate_limit_buckets IS
  'Contadores de rate limit. Escrita só via try_consume_rate_limit (SECURITY DEFINER).';

CREATE OR REPLACE FUNCTION public.rate_limited_decision()
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT jsonb_build_object(
    'decision', 'rate_limited',
    'message', 'Muitas tentativas. Aguarde um minuto e tente novamente.'
  );
$$;

CREATE OR REPLACE FUNCTION public.try_consume_rate_limit(
  p_action text,
  p_max integer DEFAULT 30,
  p_window_seconds integer DEFAULT 60
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_subject uuid := auth.uid();
  v_max integer := GREATEST(coalesce(p_max, 30), 1);
  v_window integer := GREATEST(coalesce(p_window_seconds, 60), 1);
  v_window_start timestamptz;
  v_count integer;
BEGIN
  -- Já contabilizado nesta transação (wrapper → RPC interna).
  IF current_setting('vita.rate_limited', true) = '1' THEN
    RETURN true;
  END IF;

  IF v_subject IS NULL OR coalesce(btrim(p_action), '') = '' THEN
    RETURN false;
  END IF;

  v_window_start := to_timestamp(
    floor(extract(epoch FROM clock_timestamp()) / v_window) * v_window
  );

  DELETE FROM public.rate_limit_buckets
   WHERE action = p_action
     AND subject = v_subject
     AND window_start < v_window_start;

  INSERT INTO public.rate_limit_buckets (action, subject, window_start, hit_count)
  VALUES (p_action, v_subject, v_window_start, 1)
  ON CONFLICT (action, subject, window_start)
  DO UPDATE SET hit_count = public.rate_limit_buckets.hit_count + 1
  RETURNING hit_count INTO v_count;

  IF v_count > v_max THEN
    RETURN false;
  END IF;

  PERFORM set_config('vita.rate_limited', '1', true);
  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.try_consume_rate_limit(text, integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.try_consume_rate_limit(text, integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.rate_limited_decision() TO PUBLIC;

COMMENT ON FUNCTION public.try_consume_rate_limit(text, integer, integer) IS
  'Incrementa o bucket (ação + auth.uid() + janela). false = acima do teto.';

-- ── Renomeia implementações atuais para *_inner (idempotente)
DO $$
BEGIN
  IF to_regprocedure('public.validate_loyalty_card_inner(text, uuid)') IS NULL
     AND to_regprocedure('public.validate_loyalty_card(text, uuid)') IS NOT NULL THEN
    ALTER FUNCTION public.validate_loyalty_card(text, uuid)
      RENAME TO validate_loyalty_card_inner;
  END IF;

  IF to_regprocedure('public.validate_member_qr_inner(uuid, uuid)') IS NULL
     AND to_regprocedure('public.validate_member_qr(uuid, uuid)') IS NOT NULL THEN
    ALTER FUNCTION public.validate_member_qr(uuid, uuid)
      RENAME TO validate_member_qr_inner;
  END IF;

  IF to_regprocedure('public.validate_member_code_inner(text, uuid)') IS NULL
     AND to_regprocedure('public.validate_member_code(text, uuid)') IS NOT NULL THEN
    ALTER FUNCTION public.validate_member_code(text, uuid)
      RENAME TO validate_member_code_inner;
  END IF;

  IF to_regprocedure('public.validate_dependent_card_inner(uuid, uuid)') IS NULL
     AND to_regprocedure('public.validate_dependent_card(uuid, uuid)') IS NOT NULL THEN
    ALTER FUNCTION public.validate_dependent_card(uuid, uuid)
      RENAME TO validate_dependent_card_inner;
  END IF;

  IF to_regprocedure('public.validate_dependent_qr_inner(text, uuid, uuid)') IS NULL
     AND to_regprocedure('public.validate_dependent_qr(text, uuid, uuid)') IS NOT NULL THEN
    ALTER FUNCTION public.validate_dependent_qr(text, uuid, uuid)
      RENAME TO validate_dependent_qr_inner;
  END IF;

  IF to_regprocedure('public.confirm_partner_validation_inner(uuid, text, uuid, numeric, text)') IS NULL
     AND to_regprocedure('public.confirm_partner_validation(uuid, text, uuid, numeric, text)') IS NOT NULL THEN
    ALTER FUNCTION public.confirm_partner_validation(uuid, text, uuid, numeric, text)
      RENAME TO confirm_partner_validation_inner;
  END IF;
END $$;

-- Cliente e PostgREST só enxergam os wrappers.
REVOKE ALL ON FUNCTION public.validate_loyalty_card_inner(text, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.validate_member_qr_inner(uuid, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.validate_member_code_inner(text, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.validate_dependent_card_inner(uuid, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.validate_dependent_qr_inner(text, uuid, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.confirm_partner_validation_inner(uuid, text, uuid, numeric, text) FROM PUBLIC, anon, authenticated;

-- 30 scans / 60s — enumeração de código de 8 dígitos e UUID
CREATE OR REPLACE FUNCTION public.validate_loyalty_card(
  p_payload text,
  p_actor_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NOT public.try_consume_rate_limit('loyalty_validate', 30, 60) THEN
    RETURN public.rate_limited_decision();
  END IF;
  RETURN public.validate_loyalty_card_inner(p_payload, p_actor_user_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.validate_member_qr(
  p_user_id uuid,
  p_actor_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NOT public.try_consume_rate_limit('loyalty_validate', 30, 60) THEN
    RETURN public.rate_limited_decision();
  END IF;
  RETURN public.validate_member_qr_inner(p_user_id, p_actor_user_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.validate_member_code(
  p_member_code text,
  p_actor_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NOT public.try_consume_rate_limit('loyalty_validate', 30, 60) THEN
    RETURN public.rate_limited_decision();
  END IF;
  RETURN public.validate_member_code_inner(p_member_code, p_actor_user_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.validate_dependent_card(
  p_dependent_id uuid,
  p_actor_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NOT public.try_consume_rate_limit('loyalty_validate', 30, 60) THEN
    RETURN public.rate_limited_decision();
  END IF;
  RETURN public.validate_dependent_card_inner(p_dependent_id, p_actor_user_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.validate_dependent_qr(
  p_qr_token text,
  p_actor_user_id uuid,
  p_establishment_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NOT public.try_consume_rate_limit('loyalty_validate', 30, 60) THEN
    RETURN public.rate_limited_decision();
  END IF;
  RETURN public.validate_dependent_qr_inner(p_qr_token, p_actor_user_id, p_establishment_id);
END;
$$;

-- 20 confirmações / 60s no balcão do parceiro
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
BEGIN
  IF NOT public.try_consume_rate_limit('partner_confirm', 20, 60) THEN
    RETURN jsonb_build_object(
      'ok', false,
      'message', 'Muitas tentativas. Aguarde um minuto e tente novamente.'
    );
  END IF;
  RETURN public.confirm_partner_validation_inner(
    p_holder_user_id, p_member_name, p_dependent_id, p_original_value, p_plan_level);
END;
$$;

REVOKE ALL ON FUNCTION public.validate_loyalty_card(text, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.validate_member_qr(uuid, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.validate_member_code(text, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.validate_dependent_card(uuid, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.validate_dependent_qr(text, uuid, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.confirm_partner_validation(uuid, text, uuid, numeric, text) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.validate_loyalty_card(text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_member_qr(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_member_code(text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_dependent_card(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_dependent_qr(text, uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_partner_validation(uuid, text, uuid, numeric, text) TO authenticated;
