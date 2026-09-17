-- Tokens FCM por aparelho. O envio em si é a Edge Function send-push-campaign.

CREATE TABLE IF NOT EXISTS public.device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user
  ON public.device_tokens (user_id);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own device tokens" ON public.device_tokens;
CREATE POLICY "Users manage own device tokens"
  ON public.device_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view device tokens" ON public.device_tokens;
CREATE POLICY "Admins can view device tokens"
  ON public.device_tokens FOR SELECT
  USING (public.is_admin());

REVOKE ALL ON TABLE public.device_tokens FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.device_tokens TO authenticated;

COMMENT ON TABLE public.device_tokens IS
  'Tokens FCM do aparelho. Escrita pelo próprio usuário; leitura admin para diagnóstico.';
