-- Garante que profiles.name seja preenchido a partir do metadata do Auth
-- (Google: full_name / name / given_name) quando o perfil existir com nome vazio.
-- Também corrige ensure_own_profile: no ON CONFLICT, completa name vazio.

-- 1) ensure_own_profile: cria perfil e completa name vazio em contas existentes
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
    NULLIF(btrim(u.raw_user_meta_data->>'full_name'), ''),
    NULLIF(btrim(u.raw_user_meta_data->>'name'), ''),
    NULLIF(btrim(u.raw_user_meta_data->>'given_name'), ''),
    split_part(v_email, '@', 1),
    'Usuario'
  );

  INSERT INTO public.profiles (id, name, email, role, avatar_url, member_code)
  VALUES (
    u.id,
    v_name,
    v_email,
    'user',
    COALESCE(
      u.raw_user_meta_data->>'avatar_url',
      u.raw_user_meta_data->>'picture'
    ),
    public.generate_member_code()
  )
  ON CONFLICT (id) DO UPDATE
    SET name = CASE
          WHEN btrim(COALESCE(public.profiles.name, '')) = ''
            THEN EXCLUDED.name
          ELSE public.profiles.name
        END,
        avatar_url = COALESCE(public.profiles.avatar_url, EXCLUDED.avatar_url),
        updated_at = NOW();

  PERFORM public.assign_member_code_if_missing(u.id);
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_own_profile() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ensure_own_profile() TO authenticated;

-- 2) Backfill one-shot: preenche names vazios a partir do Auth
UPDATE public.profiles p
SET
  name = COALESCE(
    NULLIF(btrim(u.raw_user_meta_data->>'full_name'), ''),
    NULLIF(btrim(u.raw_user_meta_data->>'name'), ''),
    NULLIF(btrim(u.raw_user_meta_data->>'given_name'), ''),
    split_part(COALESCE(u.email, p.email), '@', 1),
    p.name
  ),
  updated_at = NOW()
FROM auth.users u
WHERE u.id = p.id
  AND btrim(COALESCE(p.name, '')) = '';
