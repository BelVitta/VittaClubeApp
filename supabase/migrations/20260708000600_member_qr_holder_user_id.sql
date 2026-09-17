-- Adiciona holder_user_id na resposta 'approved' de validate_member_qr
-- (= o próprio p_user_id aqui, já que é o titular sendo validado) pra
-- padronizar com validate_dependent_qr — ConsultationValueSheet usa esse
-- campo pra saber em que user_id gravar a consulta, independente de qual
-- das duas RPCs foi chamada.
CREATE OR REPLACE FUNCTION public.validate_member_qr(
  p_user_id       UUID,
  p_actor_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_role     TEXT;
  v_member_name    TEXT;
  v_sub            RECORD;
  v_discount       NUMERIC(5,2) := 0;
  v_can_use_qr     BOOLEAN      := FALSE;
BEGIN
  SELECT role::TEXT
    INTO v_actor_role
    FROM public.profiles
   WHERE id = p_actor_user_id;

  IF NOT FOUND OR v_actor_role <> 'admin' THEN
    RETURN jsonb_build_object(
      'decision', 'refused',
      'message',  'Operação não autorizada. Apenas admins podem validar QR codes.'
    );
  END IF;

  SELECT name
    INTO v_member_name
    FROM public.profiles
   WHERE id = p_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'decision', 'invalid_token',
      'message',  'QR inválido: membro não encontrado.'
    );
  END IF;

  SELECT *
    INTO v_sub
    FROM public.subscriptions
   WHERE user_id   = p_user_id
     AND is_current = TRUE
   LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'decision',    'refused',
      'message',     'Membro sem assinatura ativa.',
      'member_name', v_member_name
    );
  END IF;

  v_can_use_qr := CASE
    WHEN v_sub.status = 'active'
         AND v_sub.payment_access_status = 'allowed'
      THEN TRUE
    WHEN v_sub.status = 'payment_pending'
         AND v_sub.payment_access_status IN ('allowed', 'warning_pending')
      THEN TRUE
    WHEN v_sub.status = 'cancelled'
         AND v_sub.current_period_end IS NOT NULL
         AND v_sub.current_period_end >= NOW()
      THEN TRUE
    ELSE FALSE
  END;

  IF NOT v_can_use_qr THEN
    RETURN jsonb_build_object(
      'decision',    'overdue_holder',
      'message',     'Assinatura bloqueada ou com pagamento pendente. Membro deve regularizar.',
      'member_name', v_member_name,
      'plan_level',  v_sub.plan_level_status::TEXT
    );
  END IF;

  SELECT discount_percentage
    INTO v_discount
    FROM public.badges
   WHERE level_name::TEXT = v_sub.plan_level_status::TEXT
   LIMIT 1;

  v_discount := COALESCE(v_discount, 0);

  RETURN jsonb_build_object(
    'decision',            'approved',
    'message',             format(
                             'Membro ativo. Desconto de %s%% aplicável.',
                             v_discount
                           ),
    'member_name',         v_member_name,
    'plan_level',          v_sub.plan_level_status::TEXT,
    'discount_percentage', v_discount,
    'subscription_id',     v_sub.id,
    'holder_user_id',      p_user_id
  );
END;
$$;
