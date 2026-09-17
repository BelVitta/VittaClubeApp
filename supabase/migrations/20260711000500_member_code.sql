-- Código de membro curto (8 dígitos) para digitação na recepção quando o QR falha.
-- O QR da carteirinha continua usando profiles.id (UUID) na fase 1.

-- 1) Coluna + unicidade
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS member_code text;

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_member_code_unique
  ON public.profiles (member_code)
  WHERE member_code IS NOT NULL;

COMMENT ON COLUMN public.profiles.member_code IS
  'Código numérico de 8 dígitos para identificação manual do membro na recepção.';

-- 2) Gerador com retry em colisão
CREATE OR REPLACE FUNCTION public.generate_member_code()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_code text;
  v_attempt int := 0;
BEGIN
  LOOP
    v_attempt := v_attempt + 1;
    -- 8 dígitos, evita 00000000
    v_code := lpad((floor(random() * 99999999) + 1)::bigint::text, 8, '0');

    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE member_code = v_code
    );

    IF v_attempt > 50 THEN
      RAISE EXCEPTION 'Não foi possível gerar member_code único';
    END IF;
  END LOOP;

  RETURN v_code;
END;
$$;

REVOKE ALL ON FUNCTION public.generate_member_code() FROM PUBLIC;

-- 3) Atribui código se o perfil ainda não tiver
CREATE OR REPLACE FUNCTION public.assign_member_code_if_missing(p_user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_code text;
BEGIN
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

-- 4) Backfill de contas existentes
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT id FROM public.profiles WHERE member_code IS NULL
  LOOP
    PERFORM public.assign_member_code_if_missing(r.id);
  END LOOP;
END;
$$;

-- 5) ensure_own_profile: cria perfil e garante member_code
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

  INSERT INTO public.profiles (id, name, email, role, avatar_url, member_code)
  VALUES (
    u.id,
    v_name,
    v_email,
    'user',
    u.raw_user_meta_data->>'avatar_url',
    public.generate_member_code()
  )
  ON CONFLICT (id) DO NOTHING;

  PERFORM public.assign_member_code_if_missing(u.id);
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_own_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ensure_own_profile() TO authenticated;

-- 6) handle_new_user: inclui member_code no insert
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

    BEGIN
        INSERT INTO public.profiles (
            id, name, email, role, avatar_url, member_code
        )
        VALUES (
            NEW.id,
            v_name,
            v_email,
            'user',
            NEW.raw_user_meta_data->>'avatar_url',
            public.generate_member_code()
        )
        ON CONFLICT (id) DO NOTHING;

        PERFORM public.assign_member_code_if_missing(NEW.id);
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'handle_new_user profile insert failed for %: %', NEW.id, SQLERRM;
    END;

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

-- 7) Validação por código curto (reusa validate_member_qr)
CREATE OR REPLACE FUNCTION public.validate_member_code(
  p_member_code text,
  p_actor_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_code text;
  v_user_id uuid;
BEGIN
  IF auth.uid() IS NULL OR p_actor_user_id <> auth.uid()
     OR NOT public.is_admin() THEN
    RETURN jsonb_build_object(
      'decision', 'refused',
      'message', 'Operação não autorizada.'
    );
  END IF;

  v_code := regexp_replace(coalesce(p_member_code, ''), '\D', '', 'g');
  IF length(v_code) <> 8 THEN
    RETURN jsonb_build_object(
      'decision', 'invalid_token',
      'message', 'Código inválido. Use os 8 dígitos da carteirinha.'
    );
  END IF;

  SELECT id INTO v_user_id
    FROM public.profiles
   WHERE member_code = v_code
   LIMIT 1;

  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'decision', 'invalid_token',
      'message', 'Código não encontrado.'
    );
  END IF;

  RETURN public.validate_member_qr(v_user_id, p_actor_user_id);
END;
$$;

REVOKE ALL ON FUNCTION public.validate_member_code(text, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.validate_member_code(text, uuid) TO authenticated;

COMMENT ON FUNCTION public.validate_member_code(text, uuid) IS
  'Valida membro pelo código curto de 8 dígitos (entrada manual na recepção).';
