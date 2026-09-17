-- Higiene: remover EXECUTE residual de anon nas RPCs autenticadas.
REVOKE ALL ON FUNCTION public.get_user_sensitive_profile(uuid) FROM anon;
REVOKE ALL ON FUNCTION public.update_user_sensitive_profile(uuid, text, text) FROM anon;
REVOKE ALL ON FUNCTION public.ensure_own_profile() FROM anon;
REVOKE ALL ON FUNCTION public.assign_member_code_if_missing(uuid) FROM anon;
REVOKE ALL ON FUNCTION public.validate_member_qr(uuid, uuid) FROM anon;
REVOKE ALL ON FUNCTION public.validate_member_code(text, uuid) FROM anon;

GRANT EXECUTE ON FUNCTION public.get_user_sensitive_profile(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_sensitive_profile(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_own_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_member_code_if_missing(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_member_qr(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_member_code(text, uuid) TO authenticated;
