-- Retorna CPF/telefone somente para o painel administrativo autorizado.
-- Os valores continuam criptografados em public.profiles.
CREATE OR REPLACE FUNCTION public.get_user_sensitive_profile(p_user_id uuid)
RETURNS TABLE(cpf text, phone text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF auth.uid() IS NULL OR (auth.uid() <> p_user_id
     AND NOT (public.is_admin() OR public.is_financeiro())) THEN
    RAISE EXCEPTION 'not authorized';
  END IF;

  RETURN QUERY
  SELECT
    CASE WHEN p.cpf_encrypted IS NULL THEN ''
         ELSE public.decrypt_sensitive(p.cpf_encrypted) END,
    CASE WHEN p.phone_encrypted IS NULL THEN ''
         ELSE public.decrypt_sensitive(p.phone_encrypted) END
  FROM public.profiles p
  WHERE p.id = p_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_sensitive_profile(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_sensitive_profile(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.update_user_sensitive_profile(
  p_user_id uuid,
  p_cpf text,
  p_phone text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_cpf text := nullif(regexp_replace(coalesce(p_cpf, ''), '\D', '', 'g'), '');
  v_phone text := nullif(trim(coalesce(p_phone, '')), '');
BEGIN
  IF auth.uid() IS NULL OR (auth.uid() <> p_user_id
     AND NOT (public.is_admin() OR public.is_financeiro())) THEN
    RAISE EXCEPTION 'not authorized';
  END IF;
  IF v_cpf IS NOT NULL AND length(v_cpf) <> 11 THEN
    RAISE EXCEPTION 'invalid cpf';
  END IF;

  UPDATE public.profiles
     SET cpf_encrypted = CASE WHEN v_cpf IS NULL THEN NULL ELSE public.encrypt_sensitive(v_cpf) END,
         cpf_hash = CASE WHEN v_cpf IS NULL THEN NULL ELSE public.hash_cpf(v_cpf) END,
         phone_encrypted = CASE WHEN v_phone IS NULL THEN NULL ELSE public.encrypt_sensitive(v_phone) END,
         updated_at = now()
   WHERE id = p_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.update_user_sensitive_profile(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_user_sensitive_profile(uuid, text, text) TO authenticated;
