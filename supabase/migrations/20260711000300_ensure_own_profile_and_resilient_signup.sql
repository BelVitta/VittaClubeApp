-- Garante que o perfil do usuário autenticado existe (recovery se handle_new_user falhou).
-- Também torna o signup resiliente: nome/e-mail sempre gravam; CPF/telefone
-- criptografados são best-effort (falha de app.encryption_key não engole o INSERT).

CREATE OR REPLACE FUNCTION public.ensure_own_profile()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  u auth.users%ROWTYPE;
  v_name text;
  v_email text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  SELECT * INTO u FROM auth.users WHERE id = auth.uid();
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user not found';
  END IF;

  v_email := COALESCE(NULLIF(u.email, ''), u.id::text || '@users.local');
  v_name := COALESCE(
    NULLIF(u.raw_user_meta_data->>'name', ''),
    NULLIF(u.raw_user_meta_data->>'full_name', ''),
    split_part(v_email, '@', 1),
    'Usuario'
  );

  INSERT INTO public.profiles (id, name, email, role, avatar_url)
  VALUES (
    u.id,
    v_name,
    v_email,
    'user',
    u.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_own_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ensure_own_profile() TO authenticated;

-- Signup resiliente: perfil com nome/e-mail sempre; sensíveis em update separado.
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_cpf   TEXT := NULLIF(NEW.raw_user_meta_data->>'cpf', '');
    v_phone TEXT := NULLIF(NEW.raw_user_meta_data->>'phone', '');
    v_name  TEXT := COALESCE(
        NULLIF(NEW.raw_user_meta_data->>'name', ''),
        NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
        split_part(COALESCE(NEW.email, NEW.id::text || '@users.local'), '@', 1)
    );
    v_email TEXT := COALESCE(NULLIF(NEW.email, ''), NEW.id::text || '@users.local');
    v_receptionist_code text := upper(nullif(NEW.raw_user_meta_data->>'receptionist_code', ''));
    v_receptionist_id uuid;
BEGIN
    IF v_cpf IS NOT NULL AND NOT public.check_cpf_available(v_cpf) THEN
        RAISE EXCEPTION 'Este CPF já está cadastrado.'
            USING ERRCODE = 'unique_violation';
    END IF;

    -- 1) Perfil público (não depende de encryption_key)
    BEGIN
        INSERT INTO public.profiles (
            id, name, email, role, avatar_url
        )
        VALUES (
            NEW.id,
            v_name,
            v_email,
            'user',
            NEW.raw_user_meta_data->>'avatar_url'
        )
        ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'handle_new_user profile insert failed for %: %', NEW.id, SQLERRM;
    END;

    -- 2) Dados sensíveis (best-effort — falha de crypto não apaga o perfil)
    IF v_cpf IS NOT NULL OR v_phone IS NOT NULL THEN
        BEGIN
            UPDATE public.profiles
               SET cpf_encrypted = CASE
                     WHEN v_cpf IS NULL THEN cpf_encrypted
                     ELSE public.encrypt_sensitive(v_cpf)
                   END,
                   cpf_hash = CASE
                     WHEN v_cpf IS NULL THEN cpf_hash
                     ELSE public.hash_cpf(v_cpf)
                   END,
                   phone_encrypted = CASE
                     WHEN v_phone IS NULL THEN phone_encrypted
                     ELSE public.encrypt_sensitive(v_phone)
                   END,
                   updated_at = now()
             WHERE id = NEW.id;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'handle_new_user sensitive update failed for %: %', NEW.id, SQLERRM;
        END;
    END IF;

    -- 3) Código de recepcionista (best-effort)
    IF v_receptionist_code IS NOT NULL THEN
        BEGIN
            SELECT id INTO v_receptionist_id
              FROM public.profiles
             WHERE receptionist_code = v_receptionist_code
               AND role = 'admin';

            IF v_receptionist_id IS NOT NULL THEN
                INSERT INTO public.receptionist_referrals (receptionist_id, referral_code, referred_user_id)
                VALUES (v_receptionist_id, v_receptionist_code, NEW.id)
                ON CONFLICT (referred_user_id) DO NOTHING;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'handle_new_user receptionist link failed for %: %', NEW.id, SQLERRM;
        END;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
