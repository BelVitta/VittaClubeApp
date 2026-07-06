-- ============================================================
-- RPC: validate_member_qr
--
-- Objetivo:
--   Validar o QR Code da carteirinha de um membro (que codifica o userId)
--   e retornar o status da assinatura, dados do membro e percentual de
--   desconto aplicável para o nível de badge atual.
--
-- Chamada pelo admin scanner após ler um QR no formato UUID.
-- Diferente de validate_dependent_qr (que valida agendamentos de dependentes),
-- esta função valida o titular da carteirinha para desconto em consulta avulsa.
--
-- Parâmetros:
--   p_user_id       — UUID do membro lido no QR
--   p_actor_user_id — UUID do admin que está realizando a validação
--
-- Retorno (JSONB):
--   decision            : approved | refused | overdue_holder | invalid_token
--   message             : Mensagem legível para exibição no app
--   member_name         : Nome completo do membro (quando encontrado)
--   plan_level          : Nível atual (bronze | prata | ouro | diamante | ...)
--   discount_percentage : Percentual de desconto do badge (0 se não aplicável)
--   subscription_id     : UUID da assinatura ativa (quando aprovado)
-- ============================================================

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

  -- ── 1. Verificar se o ator tem permissão (role admin) ──────
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

  -- ── 2. Verificar se o membro existe ────────────────────────
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

  -- ── 3. Buscar assinatura ativa do membro ───────────────────
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

  -- ── 4. Replicar lógica de can_use_qr ──────────────────────
  -- (mesma regra da view current_user_payment_status)
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

  -- ── 5. Buscar desconto do badge ────────────────────────────
  -- Cast TEXT para TEXT: plan_level_status (bronze/prata/ouro/diamante/...)
  -- é comparado com badges.level_name (badge_level enum: bronze/prata/ouro/diamante).
  -- Níveis sem badge (none, inadimplente, cancelado) retornam discount = 0.
  SELECT discount_percentage
    INTO v_discount
    FROM public.badges
   WHERE level_name::TEXT = v_sub.plan_level_status::TEXT
   LIMIT 1;

  v_discount := COALESCE(v_discount, 0);

  -- ── 6. Retornar aprovação com dados do membro ──────────────
  RETURN jsonb_build_object(
    'decision',            'approved',
    'message',             format(
                             'Membro ativo. Desconto de %s%% aplicável.',
                             v_discount
                           ),
    'member_name',         v_member_name,
    'plan_level',          v_sub.plan_level_status::TEXT,
    'discount_percentage', v_discount,
    'subscription_id',     v_sub.id
  );

END;
$$;

-- ── Permissões ─────────────────────────────────────────────────────────────
-- Apenas usuários autenticados podem chamar a função.
-- A verificação de role admin acontece dentro da função (linha 1).
REVOKE ALL    ON FUNCTION public.validate_member_qr(UUID, UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.validate_member_qr(UUID, UUID) TO authenticated;

-- ── Comentário ─────────────────────────────────────────────────────────────
COMMENT ON FUNCTION public.validate_member_qr(UUID, UUID) IS
  'Valida o QR Code da carteirinha de um membro e retorna status da assinatura '
  'e percentual de desconto para uso pelo admin scanner. '
  'Parâmetros: p_user_id (UUID do membro), p_actor_user_id (UUID do admin).';
