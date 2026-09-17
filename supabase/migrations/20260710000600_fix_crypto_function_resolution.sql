-- Supabase instala pgcrypto no schema `extensions` em projetos hospedados.
-- As funções antigas usavam nomes não qualificados e falhavam ao serem
-- chamadas por RPCs com search_path restrito.
CREATE OR REPLACE FUNCTION public.hash_cpf(raw_cpf text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = pg_catalog, extensions, public
AS $$
  SELECT encode(extensions.digest(convert_to(raw_cpf, 'UTF8'), 'sha256'), 'hex');
$$;

CREATE OR REPLACE FUNCTION public.encrypt_sensitive(raw_text text)
RETURNS bytea
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN extensions.pgp_sym_encrypt(raw_text, current_setting('app.encryption_key'));
END;
$$;

CREATE OR REPLACE FUNCTION public.decrypt_sensitive(encrypted_data bytea)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RETURN extensions.pgp_sym_decrypt(encrypted_data, current_setting('app.encryption_key'));
END;
$$;
