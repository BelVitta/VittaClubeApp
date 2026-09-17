-- Hardening de segurança (audit RLS / SECURITY DEFINER).
-- 1) REVOKE primitives de crypto e helpers internos de client roles
-- 2) INSERT profiles restrito (id = auth.uid(), role = user)
-- 3) UPDATE próprio perfil: colunas privilegiadas imutáveis
-- 4) assign_member_code_if_missing só self/admin

-- ═══════════════════════════════════════════════════════════
-- 1) Crypto / helpers — sem EXECUTE para anon/authenticated/public
-- ═══════════════════════════════════════════════════════════
-- Funções SECURITY DEFINER do owner (postgres) ainda se chamam entre si.
REVOKE ALL ON FUNCTION public._get_encryption_key() FROM PUBLIC;
REVOKE ALL ON FUNCTION public._get_encryption_key() FROM anon, authenticated;

REVOKE ALL ON FUNCTION public.encrypt_sensitive(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.encrypt_sensitive(text) FROM anon, authenticated;

REVOKE ALL ON FUNCTION public.decrypt_sensitive(bytea) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.decrypt_sensitive(bytea) FROM anon, authenticated;

-- Variantes legadas se existirem
DO $$
BEGIN
  IF to_regprocedure('public.encrypt_cpf(text)') IS NOT NULL THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.encrypt_cpf(text) FROM PUBLIC, anon, authenticated';
  END IF;
  IF to_regprocedure('public.decrypt_cpf(bytea)') IS NOT NULL THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.decrypt_cpf(bytea) FROM PUBLIC, anon, authenticated';
  END IF;
END $$;

-- Gerador de código: só uso interno (assign_member_code / triggers)
REVOKE ALL ON FUNCTION public.generate_member_code() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.generate_member_code() FROM anon, authenticated;

-- RPCs de negócio que o app DEVE continuar chamando
-- (reafirma grants corretos após higiene — sem anon)
REVOKE ALL ON FUNCTION public.get_user_sensitive_profile(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_user_sensitive_profile(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.update_user_sensitive_profile(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_user_sensitive_profile(uuid, text, text) TO authenticated;

REVOKE ALL ON FUNCTION public.ensure_own_profile() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ensure_own_profile() TO authenticated;

REVOKE ALL ON FUNCTION public.validate_member_qr(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.validate_member_qr(uuid, uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.validate_member_code(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.validate_member_code(text, uuid) TO authenticated;

-- ═══════════════════════════════════════════════════════════
-- 2) assign_member_code_if_missing — só o próprio usuário ou admin
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.assign_member_code_if_missing(p_user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_code text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  -- Self-service ou admin/financeiro (painel).
  IF p_user_id IS DISTINCT FROM auth.uid()
     AND NOT (public.is_admin() OR public.is_financeiro()) THEN
    RAISE EXCEPTION 'not authorized';
  END IF;

  SELECT member_code INTO v_code FROM public.profiles WHERE id = p_user_id;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  IF v_code IS NOT NULL AND btrim(v_code) <> '' THEN
    RETURN v_code;
  END IF;

  v_code := public.generate_member_code();
  UPDATE public.profiles SET member_code = v_code WHERE id = p_user_id;
  RETURN v_code;
END;
$$;

REVOKE ALL ON FUNCTION public.assign_member_code_if_missing(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assign_member_code_if_missing(uuid) TO authenticated;

-- ═══════════════════════════════════════════════════════════
-- 3) INSERT profiles — só o próprio id, role user
-- ═══════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "Allow profile creation on signup" ON public.profiles;

CREATE POLICY "Users can insert own profile as user"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    id = auth.uid()
    AND role = 'user'::public.user_role
  );

-- ═══════════════════════════════════════════════════════════
-- 4) Bloquear colunas privilegiadas no UPDATE do próprio perfil
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.protect_profile_privileged_columns()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  -- service_role / triggers internos de sistema passam.
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- Financeiro e admin podem alterar o que as policies de UPDATE permitem
  -- (role ainda é bloqueado para admin pelo prevent_non_financeiro_role_change).
  IF public.is_admin() OR public.is_financeiro() THEN
    RETURN NEW;
  END IF;

  -- Usuário comum: não mexe em identidade, papel, status, códigos, hashes.
  IF NEW.id IS DISTINCT FROM OLD.id THEN
    RAISE EXCEPTION 'id imutável';
  END IF;
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'role imutável para o usuário';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    RAISE EXCEPTION 'status imutável para o usuário';
  END IF;
  IF NEW.member_code IS DISTINCT FROM OLD.member_code THEN
    RAISE EXCEPTION 'member_code imutável para o usuário';
  END IF;
  IF NEW.receptionist_code IS DISTINCT FROM OLD.receptionist_code THEN
    RAISE EXCEPTION 'receptionist_code imutável para o usuário';
  END IF;
  IF NEW.cpf_encrypted IS DISTINCT FROM OLD.cpf_encrypted
     OR NEW.cpf_hash IS DISTINCT FROM OLD.cpf_hash
     OR NEW.phone_encrypted IS DISTINCT FROM OLD.phone_encrypted THEN
    RAISE EXCEPTION 'dados sensíveis só via RPC update_user_sensitive_profile';
  END IF;
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    RAISE EXCEPTION 'email imutável por este caminho';
  END IF;
  IF NEW.member_since IS DISTINCT FROM OLD.member_since THEN
    RAISE EXCEPTION 'member_since imutável';
  END IF;
  IF NEW.first_subscription_converted_at IS DISTINCT FROM OLD.first_subscription_converted_at THEN
    RAISE EXCEPTION 'first_subscription_converted_at imutável';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_profile_privileged_columns ON public.profiles;
CREATE TRIGGER protect_profile_privileged_columns
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_privileged_columns();

-- ═══════════════════════════════════════════════════════════
-- 5) Higiene extra: record_subscription_access_event não é API de cliente
-- ═══════════════════════════════════════════════════════════
DO $$
BEGIN
  IF to_regprocedure(
    'public.record_subscription_access_event(uuid,uuid,subscription_status,subscription_status,payment_access_status,payment_access_status,text,text,jsonb)'
  ) IS NOT NULL THEN
    EXECUTE $q$
      REVOKE ALL ON FUNCTION public.record_subscription_access_event(
        uuid, uuid, subscription_status, subscription_status,
        payment_access_status, payment_access_status, text, text, jsonb
      ) FROM PUBLIC, anon, authenticated
    $q$;
  END IF;
END $$;
