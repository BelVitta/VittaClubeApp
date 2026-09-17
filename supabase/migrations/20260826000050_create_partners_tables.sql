-- Partners lived only in schema.sql and never in a migration, so remote
-- projects have partner_applications but no public.partners.
-- This creates the establishment tables the loyalty MVP depends on.

-- Role used by partner login (same app, role = parceiro).
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'parceiro';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type WHERE typname = 'partner_category' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE TYPE public.partner_category AS ENUM (
      'laboratorio', 'clinica', 'farmacia', 'otica', 'outro'
    );
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.partners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category public.partner_category NOT NULL,
  code TEXT NOT NULL UNIQUE,
  address TEXT,
  phone_encrypted BYTEA,
  logo_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_partners_profile ON public.partners(profile_id);
CREATE INDEX IF NOT EXISTS idx_partners_category ON public.partners(category);
CREATE INDEX IF NOT EXISTS idx_partners_code ON public.partners(code);
CREATE INDEX IF NOT EXISTS idx_partners_active ON public.partners(is_active);

CREATE TABLE IF NOT EXISTS public.partner_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  original_price NUMERIC(10,2) NOT NULL CHECK (original_price >= 0),
  discounted_price NUMERIC(10,2) NOT NULL CHECK (discounted_price >= 0),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_partner_services_partner
  ON public.partner_services(partner_id);
CREATE INDEX IF NOT EXISTS idx_partner_services_active
  ON public.partner_services(is_active);

CREATE TABLE IF NOT EXISTS public.partner_validations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  service_id UUID REFERENCES public.partner_services(id) ON DELETE SET NULL,
  user_name TEXT NOT NULL,
  user_badge_level TEXT NOT NULL DEFAULT 'bronze',
  discount_applied NUMERIC(10,2) NOT NULL DEFAULT 0,
  service_name TEXT NOT NULL DEFAULT 'Carteirinha Vita Clube',
  validated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_partner_validations_partner
  ON public.partner_validations(partner_id);
CREATE INDEX IF NOT EXISTS idx_partner_validations_user
  ON public.partner_validations(user_id);
CREATE INDEX IF NOT EXISTS idx_partner_validations_date
  ON public.partner_validations(validated_at DESC);

ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_validations ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_parceiro()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = pg_catalog, public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role::text = 'parceiro'
  );
END;
$$;

DROP POLICY IF EXISTS "Parceiros can view own partner" ON public.partners;
CREATE POLICY "Parceiros can view own partner"
  ON public.partners FOR SELECT
  USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "Parceiros can update own partner" ON public.partners;
CREATE POLICY "Parceiros can update own partner"
  ON public.partners FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "Users can view active partners" ON public.partners;
CREATE POLICY "Users can view active partners"
  ON public.partners FOR SELECT
  USING (is_active = TRUE);

DROP POLICY IF EXISTS "Admins can manage partners" ON public.partners;
CREATE POLICY "Admins can manage partners"
  ON public.partners FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Parceiros can manage own services" ON public.partner_services;
CREATE POLICY "Parceiros can manage own services"
  ON public.partner_services FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.partners
      WHERE partners.id = partner_services.partner_id
        AND partners.profile_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.partners
      WHERE partners.id = partner_services.partner_id
        AND partners.profile_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can view active partner services" ON public.partner_services;
CREATE POLICY "Users can view active partner services"
  ON public.partner_services FOR SELECT
  USING (is_active = TRUE);

DROP POLICY IF EXISTS "Admins can manage partner services" ON public.partner_services;
CREATE POLICY "Admins can manage partner services"
  ON public.partner_services FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Parceiros can view own validations" ON public.partner_validations;
CREATE POLICY "Parceiros can view own validations"
  ON public.partner_validations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.partners
      WHERE partners.id = partner_validations.partner_id
        AND partners.profile_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can manage partner validations" ON public.partner_validations;
CREATE POLICY "Admins can manage partner validations"
  ON public.partner_validations FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.partners TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.partner_services TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.partner_validations TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_parceiro() TO authenticated;
