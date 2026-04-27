-- ============================================================
-- Fix: "Database error saving new user" no signup com Google
-- ============================================================
-- Problema:
--   O trigger handle_new_user() tentava inserir cpf_encrypted,
--   cpf_hash e phone_encrypted como NOT NULL, mas o Google OAuth
--   não fornece CPF/telefone em raw_user_meta_data. Além disso,
--   cpf_hash era UNIQUE: o hash de string vazia é constante, então
--   o 2º usuário Google sempre colidia.
--
-- Solução:
--   - CPF/telefone passam a ser opcionais no signup (nullable).
--   - UNIQUE de cpf_hash vira índice único parcial (ignora NULLs).
--   - Trigger só criptografa/hasheia quando o dado existir, e engole
--     exceções para nunca derrubar o signup (perfil pode ser
--     completado depois pelo app).
-- ============================================================

-- 1. Tornar colunas sensíveis opcionais
ALTER TABLE public.profiles ALTER COLUMN cpf_encrypted   DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN cpf_hash        DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN phone_encrypted DROP NOT NULL;

-- 2. Trocar UNIQUE inline por índice único parcial
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_cpf_hash_key;

-- Remover índice não-único anterior, se existir, e criar o único parcial
DROP INDEX IF EXISTS public.idx_profiles_cpf_hash;

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_cpf_hash_unique
    ON public.profiles(cpf_hash) WHERE cpf_hash IS NOT NULL;

-- 3. Reescrever trigger para tolerar ausência de CPF/telefone
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_cpf   TEXT := NULLIF(NEW.raw_user_meta_data->>'cpf', '');
    v_phone TEXT := NULLIF(NEW.raw_user_meta_data->>'phone', '');
    v_name  TEXT := COALESCE(
        NULLIF(NEW.raw_user_meta_data->>'name', ''),
        NULLIF(NEW.raw_user_meta_data->>'full_name', ''),  -- Google envia assim
        split_part(NEW.email, '@', 1)
    );
BEGIN
    INSERT INTO public.profiles (
        id, name, email, cpf_encrypted, cpf_hash, phone_encrypted, role, avatar_url
    )
    VALUES (
        NEW.id,
        v_name,
        NEW.email,
        CASE WHEN v_cpf   IS NOT NULL THEN encrypt_sensitive(v_cpf) END,
        CASE WHEN v_cpf   IS NOT NULL THEN hash_cpf(v_cpf)         END,
        CASE WHEN v_phone IS NOT NULL THEN encrypt_sensitive(v_phone) END,
        'user',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Nunca bloquear o signup por falha na criação do perfil.
    -- O app detecta perfil ausente e refaz/completa posteriormente.
    RAISE WARNING 'handle_new_user failed for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger já existe (on_auth_user_created). CREATE OR REPLACE FUNCTION
-- acima já atualiza a lógica executada por ele.
