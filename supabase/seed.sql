-- ============================================================
-- VITA CLUBE - Seed de dados (APENAS DEV / STAGING)
-- ============================================================
-- ATENÇÃO:
--   - NUNCA rode este script no projeto de produção.
--   - Destinado ao projeto `vita-clube-dev` para popular com
--     dados de demonstração e permitir QA com app "cheio".
--
-- Pré-requisitos:
--   1. Schema aplicado (schema.sql + migrations).
--   2. Usuário demo criado manualmente no Dashboard:
--        Authentication → Users → Add User
--        email: demo@vitaclube.com
--        password: DemoVita@2026
--        (confirme "Auto Confirm User")
--   3. Plans + plan_benefits já populados (esta migração os cria).
--
-- Rodar em: Supabase SQL Editor → New query → cole tudo → Run.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Planos oferecidos (sempre os mesmos — dev e prod)
-- ------------------------------------------------------------
INSERT INTO public.plans (id, name, subscription_type, price, discount_label, is_active)
VALUES
    ('11111111-1111-1111-1111-111111111101', 'Vita Clube Mensal',     'mensal',     34.99, NULL,       TRUE),
    ('11111111-1111-1111-1111-111111111102', 'Vita Clube Semestral',  'semestral',  29.99, '30% Off',  TRUE),
    ('11111111-1111-1111-1111-111111111103', 'Vita Clube Anual',      'anual',      29.99, 'Melhor escolha', TRUE)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------
-- 2. Benefícios dos planos
-- ------------------------------------------------------------
INSERT INTO public.plan_benefits (plan_id, title, description, sort_order) VALUES
    ('11111111-1111-1111-1111-111111111101', 'Consultas ilimitadas', 'Agende quantas consultas quiser com nossa rede médica.', 1),
    ('11111111-1111-1111-1111-111111111101', 'Descontos em parceiros', 'Use a carteirinha Vita e economize em farmácias, clínicas e academias.', 2),
    ('11111111-1111-1111-1111-111111111101', 'Sorteios exclusivos',   'Participe todo mês de prêmios reservados a assinantes.', 3),
    ('11111111-1111-1111-1111-111111111101', 'Progressão de badges',  'Bronze, Prata, Ouro e Diamante — mais benefícios em cada nível.', 4),
    ('11111111-1111-1111-1111-111111111101', 'Suporte prioritário',   'Fale direto com nossa equipe sem esperar na fila.', 5),
    ('11111111-1111-1111-1111-111111111101', 'Cancelamento sem multa','Volte quando quiser, sem taxas de saída.', 6),

    ('11111111-1111-1111-1111-111111111102', 'Tudo do plano Mensal',  'Todos os benefícios do plano mensal inclusos.', 1),
    ('11111111-1111-1111-1111-111111111102', '30% de desconto',       'Economize R$ 30 ao pagar em 6 meses.', 2),
    ('11111111-1111-1111-1111-111111111102', 'Upgrade para Prata',    'Desbloqueie o badge Prata automaticamente ao assinar.', 3),
    ('11111111-1111-1111-1111-111111111102', 'Consulta bônus',        'Ganhe uma consulta com nutricionista no 1º mês.', 4),
    ('11111111-1111-1111-1111-111111111102', 'Acesso a sorteios VIP', 'Participe de sorteios exclusivos para assinantes semestrais.', 5),
    ('11111111-1111-1111-1111-111111111102', 'Recompensas dobradas',  'Indicações rendem o dobro de pontos.', 6),

    ('11111111-1111-1111-1111-111111111103', 'Todos os benefícios',   'Tudo dos planos Mensal e Semestral.', 1),
    ('11111111-1111-1111-1111-111111111103', 'Preço equivalente ao semestral', 'Pague o mesmo por mês, mas com benefícios de plano anual.', 2),
    ('11111111-1111-1111-1111-111111111103', 'Badge Ouro instantâneo','Comece direto no nível Ouro com 15% de descontos.', 3),
    ('11111111-1111-1111-1111-111111111103', 'Cashback anual',        'Receba 10% de volta em créditos no aniversário.', 4),
    ('11111111-1111-1111-1111-111111111103', 'Prioridade em sorteios','Seu nome entra duas vezes em cada sorteio.', 5),
    ('11111111-1111-1111-1111-111111111103', 'Concierge de saúde',    'Atendimento dedicado para marcar consultas e exames.', 6)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- 3. Especialidades e profissionais (amostra)
-- ------------------------------------------------------------
INSERT INTO public.specialties (id, name, is_active) VALUES
    ('22222222-2222-2222-2222-222222222201', 'Clínica Geral',   TRUE),
    ('22222222-2222-2222-2222-222222222202', 'Nutrição',        TRUE),
    ('22222222-2222-2222-2222-222222222203', 'Fisioterapia',    TRUE),
    ('22222222-2222-2222-2222-222222222204', 'Psicologia',      TRUE)
ON CONFLICT (id) DO NOTHING;

-- Pré-requisito: app.encryption_key precisa estar definido no projeto dev.
-- Se não estiver, rode antes: ALTER DATABASE postgres SET app.encryption_key = 'dev-only-key-troque-em-prod';
DO $$
BEGIN
    PERFORM current_setting('app.encryption_key');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'app.encryption_key não configurado — profissionais não serão inseridos. Configure antes de rodar de novo.';
    RETURN;
END $$;

INSERT INTO public.professionals (id, name, specialty_id, available_days, whatsapp_encrypted, is_active) VALUES
    ('33333333-3333-3333-3333-333333333301', 'Dra. Marina Silva',    '22222222-2222-2222-2222-222222222201', ARRAY['seg','qua','sex'], encrypt_sensitive('5511999990001'), TRUE),
    ('33333333-3333-3333-3333-333333333302', 'Dr. Ricardo Alves',    '22222222-2222-2222-2222-222222222202', ARRAY['ter','qui'],       encrypt_sensitive('5511999990002'), TRUE),
    ('33333333-3333-3333-3333-333333333303', 'Dra. Laura Mendes',    '22222222-2222-2222-2222-222222222203', ARRAY['seg','ter','qua','qui','sex'], encrypt_sensitive('5511999990003'), TRUE),
    ('33333333-3333-3333-3333-333333333304', 'Dr. Pedro Ramirez',    '22222222-2222-2222-2222-222222222204', ARRAY['qua','sex'],       encrypt_sensitive('5511999990004'), TRUE)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------
-- 4. Dados do usuário demo (requer que demo@vitaclube.com já exista em auth.users)
-- ------------------------------------------------------------
DO $$
DECLARE
    v_user_id UUID;
    v_plan_id UUID := '11111111-1111-1111-1111-111111111103';  -- plano anual
    v_subscription_id UUID := gen_random_uuid();
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE email = 'demo@vitaclube.com' LIMIT 1;

    IF v_user_id IS NULL THEN
        RAISE NOTICE 'Usuário demo@vitaclube.com não existe em auth.users. Crie manualmente no Dashboard (Authentication → Users → Add User) antes de rodar o seed.';
        RETURN;
    END IF;

    -- Atualiza profile com nome bonito
    UPDATE public.profiles
       SET name = 'Diana Demonstração'
     WHERE id = v_user_id;

    -- Subscription ativa (plano anual, badge ouro)
    INSERT INTO public.subscriptions (id, user_id, plan_id, badge_level, plan_level_status, activation_date, expiration_date, is_current)
    VALUES (v_subscription_id, v_user_id, v_plan_id, 'ouro', 'ouro', NOW() - INTERVAL '8 months', NOW() + INTERVAL '4 months', TRUE)
    ON CONFLICT DO NOTHING;

    -- Badge progress
    INSERT INTO public.badge_progress (user_id, current_badge_level, consultation_count, referral_count, plan_activation_date, has_annual_plan)
    VALUES (v_user_id, 'ouro', 25, 3, NOW() - INTERVAL '8 months', TRUE)
    ON CONFLICT (user_id) DO UPDATE
       SET current_badge_level = EXCLUDED.current_badge_level,
           consultation_count  = EXCLUDED.consultation_count,
           referral_count      = EXCLUDED.referral_count,
           has_annual_plan     = EXCLUDED.has_annual_plan;

    -- Histórico de pagamentos (6 meses)
    INSERT INTO public.payments (user_id, subscription_id, amount, method, status, receipt_number, paid_at) VALUES
        (v_user_id, v_subscription_id, 359.88, 'cartao_credito', 'aprovado', 'DEMO-0001', NOW() - INTERVAL '8 months'),
        (v_user_id, v_subscription_id,  29.99, 'pix',            'aprovado', 'DEMO-0002', NOW() - INTERVAL '6 months'),
        (v_user_id, v_subscription_id,  29.99, 'boleto',         'aprovado', 'DEMO-0003', NOW() - INTERVAL '5 months'),
        (v_user_id, v_subscription_id,  29.99, 'pix',            'aprovado', 'DEMO-0004', NOW() - INTERVAL '3 months'),
        (v_user_id, v_subscription_id,  29.99, 'cartao_credito', 'aprovado', 'DEMO-0005', NOW() - INTERVAL '2 months'),
        (v_user_id, v_subscription_id,  29.99, 'cartao_credito', 'aprovado', 'DEMO-0006', NOW() - INTERVAL '1 month')
    ON CONFLICT (receipt_number) DO NOTHING;

    -- Consultas (histórico)
    INSERT INTO public.consultations (user_id, professional_id, title, subtitle, scheduled_date, status, notes) VALUES
        (v_user_id, '33333333-3333-3333-3333-333333333301', 'Consulta Clínica Geral',    'Retorno de acompanhamento',   NOW() - INTERVAL '15 days', 'realizada', 'Exames dentro da normalidade.'),
        (v_user_id, '33333333-3333-3333-3333-333333333302', 'Avaliação Nutricional',     'Ajuste de plano alimentar',   NOW() - INTERVAL '45 days', 'realizada', 'Plano reformulado.'),
        (v_user_id, '33333333-3333-3333-3333-333333333303', 'Sessão Fisioterapia',       'Tratamento de dor lombar',    NOW() - INTERVAL '60 days', 'realizada', NULL),
        (v_user_id, '33333333-3333-3333-3333-333333333304', 'Psicoterapia',              'Sessão de acompanhamento',    NOW() + INTERVAL '3 days',  'agendada',  NULL)
    ON CONFLICT DO NOTHING;

    -- Notificações
    INSERT INTO public.notifications (user_id, type, title, message, is_read, created_at) VALUES
        (v_user_id, 'sistema',  'Bem-vindo ao Vita Clube!',       'Sua assinatura está ativa. Aproveite os benefícios.', TRUE,  NOW() - INTERVAL '8 months'),
        (v_user_id, 'badge',    'Você subiu para Ouro!',          'Parabéns! Agora você tem 15% de desconto nos parceiros.', TRUE,  NOW() - INTERVAL '60 days'),
        (v_user_id, 'consulta', 'Consulta confirmada',            'Sua sessão de psicoterapia está marcada para breve.', FALSE, NOW() - INTERVAL '2 days'),
        (v_user_id, 'sorteio',  'Novo sorteio disponível',        'iPad Pro 2026 — inscreva-se até sexta-feira.',        FALSE, NOW() - INTERVAL '1 day'),
        (v_user_id, 'cupom',    'Cupom especial: VITA10',         '10% extra em farmácias conveniadas neste fim de semana.', FALSE, NOW() - INTERVAL '12 hours')
    ON CONFLICT DO NOTHING;

    -- Referrals (3 ativos)
    INSERT INTO public.referrals (referrer_id, referred_email, status, reward_granted, created_at) VALUES
        (v_user_id, 'amigo1@example.com', 'active',   TRUE,  NOW() - INTERVAL '90 days'),
        (v_user_id, 'amigo2@example.com', 'rewarded', TRUE,  NOW() - INTERVAL '45 days'),
        (v_user_id, 'amigo3@example.com', 'pending',  FALSE, NOW() - INTERVAL '5 days')
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Seed concluído para usuário demo: %', v_user_id;
END $$;
