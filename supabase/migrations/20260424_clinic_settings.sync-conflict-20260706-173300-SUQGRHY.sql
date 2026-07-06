-- ============================================================
-- Tabela de configurações da clínica (key/value)
-- ============================================================
-- Uso principal: número padrão do WhatsApp da clínica, configurável
-- pelo admin via app. RLS: todos autenticados leem, só admin escreve.

CREATE TABLE IF NOT EXISTS public.clinic_settings (
    key        TEXT PRIMARY KEY,
    value      TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.clinic_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone authenticated can read clinic_settings"
    ON public.clinic_settings;
DROP POLICY IF EXISTS "Only admins can insert clinic_settings"
    ON public.clinic_settings;
DROP POLICY IF EXISTS "Only admins can update clinic_settings"
    ON public.clinic_settings;
DROP POLICY IF EXISTS "Only admins can delete clinic_settings"
    ON public.clinic_settings;

-- Leitura: qualquer usuário autenticado
CREATE POLICY "Anyone authenticated can read clinic_settings"
    ON public.clinic_settings
    FOR SELECT
    TO authenticated
    USING (true);

-- Escrita: apenas admins (função is_admin() já existe no schema)
CREATE POLICY "Only admins can insert clinic_settings"
    ON public.clinic_settings
    FOR INSERT
    TO authenticated
    WITH CHECK (is_admin());

CREATE POLICY "Only admins can update clinic_settings"
    ON public.clinic_settings
    FOR UPDATE
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "Only admins can delete clinic_settings"
    ON public.clinic_settings
    FOR DELETE
    TO authenticated
    USING (is_admin());

-- Trigger para manter updated_at em sincronia
CREATE OR REPLACE FUNCTION public.set_clinic_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_clinic_settings_updated_at
    ON public.clinic_settings;

CREATE TRIGGER trg_clinic_settings_updated_at
    BEFORE UPDATE ON public.clinic_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.set_clinic_settings_updated_at();

-- Seed inicial: placeholder. Admin deve sobrescrever via app.
INSERT INTO public.clinic_settings (key, value)
VALUES ('default_whatsapp', '5585999000000')
ON CONFLICT (key) DO NOTHING;
