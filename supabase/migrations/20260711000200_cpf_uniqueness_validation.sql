-- Hoje o cadastro com CPF já usado por outra conta cria um "usuário
-- fantasma": o auth.users é criado normalmente, mas o INSERT em
-- public.profiles falha na constraint única de cpf_hash — e
-- handle_new_user() engole QUALQUER exceção (`WHEN OTHERS`), então o app
-- nunca mostra erro nenhum e a conta fica sem perfil (não aparece em
-- lugar nenhum que dependa de profiles).
--
-- Correção em duas partes:
-- 1. RPC pública `check_cpf_available` pro app checar ANTES de tentar o
--    cadastro (fluxo principal — dá erro claro pro usuário na hora).
-- 2. handle_new_user() passa a validar o CPF ANTES do bloco que engole
--    exceção, então mesmo numa corrida (dois cadastros simultâneos com o
--    mesmo CPF) o segundo falha de verdade em vez de virar fantasma.

CREATE OR REPLACE FUNCTION public.check_cpf_available(p_cpf text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
  v_hash text;
BEGIN
  v_hash := public.hash_cpf(regexp_replace(p_cpf, '\D', '', 'g'));
  RETURN NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE cpf_hash = v_hash
  );
END;
$$;

REVOKE ALL ON FUNCTION public.check_cpf_available(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_cpf_available(text) TO anon, authenticated;

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
    v_receptionist_code text := upper(nullif(NEW.raw_user_meta_data->>'receptionist_code', ''));
    v_receptionist_id uuid;
BEGIN
    -- Validação de CPF duplicado FORA do bloco que engole exceção — isso
    -- precisa derrubar o cadastro de verdade, não virar conta fantasma.
    IF v_cpf IS NOT NULL AND NOT public.check_cpf_available(v_cpf) THEN
        RAISE EXCEPTION 'Este CPF já está cadastrado.'
            USING ERRCODE = 'unique_violation';
    END IF;

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

        IF v_receptionist_code IS NOT NULL THEN
            SELECT id INTO v_receptionist_id
              FROM public.profiles
             WHERE receptionist_code = v_receptionist_code
               AND role = 'admin';

            IF v_receptionist_id IS NOT NULL THEN
                INSERT INTO public.receptionist_referrals (receptionist_id, referral_code, referred_user_id)
                VALUES (v_receptionist_id, v_receptionist_code, NEW.id)
                ON CONFLICT (referred_user_id) DO NOTHING;
            END IF;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        -- Qualquer outra falha (ex.: pgcrypto indisponível) não deve travar
        -- o cadastro — só o CPF duplicado, verificado acima, é bloqueante.
        RAISE WARNING 'handle_new_user failed for %: %', NEW.id, SQLERRM;
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
