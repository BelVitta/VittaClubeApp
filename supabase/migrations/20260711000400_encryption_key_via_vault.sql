-- Substitui current_setting('app.encryption_key') pelo Supabase Vault.
-- Em projetos hospedados, ALTER DATABASE/ROLE SET app.encryption_key
-- é bloqueado por permissão (ERROR 42501), o que quebrava
-- encrypt_sensitive/decrypt_sensitive (CPF/telefone no cadastro).
--
-- vault.create_secret gera a chave se ainda não existir.
-- Cada ambiente (dev/prod) fica com a sua própria chave — dados
-- já criptografados com a chave antiga (se houver) não migrariam
-- automaticamente; na prática a chave nunca esteve configurada
-- e cpf_encrypted/phone_encrypted estão NULL.

CREATE OR REPLACE FUNCTION public._get_encryption_key()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, vault, extensions, public
AS $$
DECLARE
  v_key text;
BEGIN
  SELECT ds.decrypted_secret
    INTO v_key
    FROM vault.decrypted_secrets ds
   WHERE ds.name = 'vita_clube_encryption_key'
   LIMIT 1;

  IF v_key IS NULL OR btrim(v_key) = '' THEN
    RAISE EXCEPTION
      'encryption key missing: vault secret "vita_clube_encryption_key" not found';
  END IF;

  RETURN v_key;
END;
$$;

REVOKE ALL ON FUNCTION public._get_encryption_key() FROM PUBLIC;
-- Usada apenas por outras funções SECURITY DEFINER do owner.

CREATE OR REPLACE FUNCTION public.encrypt_sensitive(raw_text text)
RETURNS bytea
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  IF raw_text IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN extensions.pgp_sym_encrypt(raw_text, public._get_encryption_key());
END;
$$;

CREATE OR REPLACE FUNCTION public.decrypt_sensitive(encrypted_data bytea)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  IF encrypted_data IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN extensions.pgp_sym_decrypt(encrypted_data, public._get_encryption_key());
END;
$$;

-- Cria o secret no Vault se ainda não existir (chave aleatória por ambiente).
DO $$
DECLARE
  v_exists boolean;
  v_key text;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM vault.secrets WHERE name = 'vita_clube_encryption_key'
  ) INTO v_exists;

  IF NOT v_exists THEN
    v_key := encode(extensions.gen_random_bytes(32), 'hex');
    PERFORM vault.create_secret(
      v_key,
      'vita_clube_encryption_key',
      'Symmetric key for CPF/phone encryption (pgp_sym)'
    );
  END IF;
END;
$$;

-- Smoke test: se falhar, a migration aborta e o histórico fica limpo.
DO $$
DECLARE
  v_cipher bytea;
  v_plain text;
BEGIN
  v_cipher := public.encrypt_sensitive('smoke-test-123');
  v_plain := public.decrypt_sensitive(v_cipher);
  IF v_plain IS DISTINCT FROM 'smoke-test-123' THEN
    RAISE EXCEPTION 'encrypt/decrypt smoke test failed';
  END IF;
END;
$$;
