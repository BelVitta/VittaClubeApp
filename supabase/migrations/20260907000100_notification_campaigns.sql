-- Campanhas in-app: histórico, preferências e RPC de envio.
-- Push FCM fica para uma fatia posterior; as linhas em notifications
-- continuam sendo a fonte da verdade.

ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'divulgacao';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'profissional';

CREATE TABLE IF NOT EXISTS public.notification_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type public.notification_type NOT NULL,
  audience TEXT NOT NULL CHECK (audience IN ('all_users', 'user')),
  target_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  recipient_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_campaigns_created
  ON public.notification_campaigns (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_campaigns_type
  ON public.notification_campaigns (type);

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS campaign_id UUID
    REFERENCES public.notification_campaigns(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_campaign
  ON public.notifications (campaign_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications (user_id, is_read, created_at DESC);

CREATE TABLE IF NOT EXISTS public.notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  sorteios BOOLEAN NOT NULL DEFAULT TRUE,
  rankings BOOLEAN NOT NULL DEFAULT TRUE,
  pagamentos BOOLEAN NOT NULL DEFAULT TRUE,
  novidades BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.notification_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage notification campaigns"
  ON public.notification_campaigns;
CREATE POLICY "Admins can manage notification campaigns"
  ON public.notification_campaigns FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Users manage own notification preferences"
  ON public.notification_preferences;
CREATE POLICY "Users manage own notification preferences"
  ON public.notification_preferences FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view notification preferences"
  ON public.notification_preferences;
CREATE POLICY "Admins can view notification preferences"
  ON public.notification_preferences FOR SELECT
  USING (public.is_admin());

REVOKE ALL ON TABLE public.notification_campaigns FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE ON TABLE public.notification_campaigns TO authenticated;

REVOKE ALL ON TABLE public.notification_preferences FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE ON TABLE public.notification_preferences TO authenticated;

CREATE OR REPLACE FUNCTION public.send_notification_campaign(
  p_title text,
  p_body text,
  p_type public.notification_type,
  p_audience text,
  p_target_user_id uuid DEFAULT NULL,
  p_data jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_title text := btrim(coalesce(p_title, ''));
  v_body text := btrim(coalesce(p_body, ''));
  v_audience text := lower(btrim(coalesce(p_audience, '')));
  v_campaign_id uuid;
  v_count integer := 0;
  v_data jsonb := coalesce(p_data, '{}'::jsonb);
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_admin() THEN
    RAISE EXCEPTION 'Sem permissão para enviar notificações.';
  END IF;

  IF v_title = '' OR v_body = '' THEN
    RAISE EXCEPTION 'Título e corpo são obrigatórios.';
  END IF;

  IF v_audience NOT IN ('all_users', 'user') THEN
    RAISE EXCEPTION 'Público inválido.';
  END IF;

  IF v_audience = 'all_users' THEN
    IF NOT public.is_financeiro() THEN
      RAISE EXCEPTION 'Apenas o financeiro pode enviar para todos os membros.';
    END IF;
    IF NOT public.try_consume_rate_limit('send_notification_broadcast', 1, 86400) THEN
      RAISE EXCEPTION 'Muitas tentativas. Aguarde um dia e tente novamente.';
    END IF;
  ELSE
    IF p_target_user_id IS NULL THEN
      RAISE EXCEPTION 'Informe o usuário destinatário.';
    END IF;
    IF NOT public.try_consume_rate_limit('send_notification_user', 10, 86400) THEN
      RAISE EXCEPTION 'Muitas tentativas. Aguarde um dia e tente novamente.';
    END IF;
  END IF;

  INSERT INTO public.notification_campaigns (
    title, body, type, audience, target_user_id, data, created_by
  ) VALUES (
    v_title, v_body, p_type, v_audience, p_target_user_id, v_data, auth.uid()
  )
  RETURNING id INTO v_campaign_id;

  INSERT INTO public.notifications (
    user_id, campaign_id, title, body, type, data
  )
  SELECT
    p.id,
    v_campaign_id,
    v_title,
    v_body,
    p_type,
    v_data
  FROM public.profiles p
  LEFT JOIN public.notification_preferences pref ON pref.user_id = p.id
  WHERE p.role = 'user'
    AND p.status = 'ativo'
    AND (
      (v_audience = 'user' AND p.id = p_target_user_id)
      OR v_audience = 'all_users'
    )
    AND (
      p_type::text NOT IN ('divulgacao', 'profissional')
      OR coalesce(pref.novidades, true)
    );

  GET DIAGNOSTICS v_count = ROW_COUNT;

  UPDATE public.notification_campaigns
     SET recipient_count = v_count
   WHERE id = v_campaign_id;

  BEGIN
    INSERT INTO public.audit_log (
      table_name, record_id, action, new_data, performed_by
    ) VALUES (
      'notification_campaigns',
      v_campaign_id,
      'INSERT',
      jsonb_build_object(
        'title', v_title,
        'type', p_type,
        'audience', v_audience,
        'target_user_id', p_target_user_id,
        'recipient_count', v_count
      ),
      auth.uid()
    );
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN jsonb_build_object(
    'campaign_id', v_campaign_id,
    'recipient_count', v_count
  );
END;
$$;

REVOKE ALL ON FUNCTION public.send_notification_campaign(
  text, text, public.notification_type, text, uuid, jsonb
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.send_notification_campaign(
  text, text, public.notification_type, text, uuid, jsonb
) TO authenticated;

COMMENT ON FUNCTION public.send_notification_campaign(
  text, text, public.notification_type, text, uuid, jsonb
) IS
  'Envia campanha in-app. Broadcast (all_users) só financeiro, 1/dia; '
  'envio a 1 usuário: admin/financeiro, 10/dia. Respeita preferência novidades '
  'para tipos divulgacao/profissional.';
