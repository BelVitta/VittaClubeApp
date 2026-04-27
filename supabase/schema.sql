-- ============================================================
-- VITA CLUBE - Schema Supabase
-- Banco normalizado, ACID, com RLS e criptografia
-- ============================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";      -- para criptografia de dados sensíveis
CREATE EXTENSION IF NOT EXISTS "pgsodium";       -- Supabase Vault (encrypt/decrypt transparente)

-- ============================================================
-- TIPOS ENUMERADOS
-- ============================================================

CREATE TYPE user_role AS ENUM ('user', 'admin', 'financeiro', 'parceiro');
CREATE TYPE user_status AS ENUM ('ativo', 'inativo');
CREATE TYPE badge_level AS ENUM ('bronze', 'prata', 'ouro', 'diamante');
CREATE TYPE subscription_type AS ENUM ('mensal', 'semestral', 'anual');
CREATE TYPE payment_method AS ENUM ('cartao_credito', 'pix', 'boleto');
CREATE TYPE payment_status AS ENUM ('aprovado', 'pendente', 'cancelado', 'estornado');
CREATE TYPE draw_status AS ENUM ('agendado', 'inscricoes_abertas', 'inscricoes_encerradas', 'realizado', 'cancelado');
CREATE TYPE referral_status AS ENUM ('pending', 'active', 'rewarded', 'expired');
CREATE TYPE notification_type AS ENUM ('sorteio', 'cupom', 'consulta', 'sistema', 'badge');
CREATE TYPE plan_level_status AS ENUM ('none', 'bronze', 'prata', 'ouro', 'diamante', 'inadimplente', 'cancelado');

-- ============================================================
-- 1. USERS (auth.users do Supabase + perfil público)
-- ============================================================
-- Supabase já cria auth.users automaticamente.
-- Esta tabela é o perfil complementar.

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    -- CPF criptografado (dado sensível - LGPD). Opcional no signup (ex.: login Google);
    -- deve ser preenchido depois via fluxo de "completar cadastro".
    cpf_encrypted BYTEA,
    -- Hash do CPF para buscas (não reversível). Opcional; unicidade garantida por índice parcial.
    cpf_hash TEXT,
    -- Telefone criptografado (dado sensível - LGPD). Opcional no signup.
    phone_encrypted BYTEA,
    role user_role NOT NULL DEFAULT 'user',
    status user_status NOT NULL DEFAULT 'ativo',
    avatar_url TEXT,
    member_since TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE UNIQUE INDEX idx_profiles_cpf_hash_unique
    ON public.profiles(cpf_hash) WHERE cpf_hash IS NOT NULL;
CREATE INDEX idx_profiles_status ON public.profiles(status);
CREATE INDEX idx_profiles_role ON public.profiles(role);

-- ============================================================
-- 2. SPECIALTIES (Especialidades médicas)
-- ============================================================

CREATE TABLE public.specialties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_specialties_active ON public.specialties(is_active);

-- ============================================================
-- 3. PROFESSIONALS (Profissionais de saúde)
-- ============================================================

CREATE TABLE public.professionals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    specialty_id UUID NOT NULL REFERENCES public.specialties(id) ON DELETE RESTRICT,
    available_days TEXT[] NOT NULL DEFAULT '{}',  -- array: {'seg','qua','sex'}
    avatar_url TEXT,
    avatar_bg_color INTEGER NOT NULL DEFAULT 0,
    -- WhatsApp criptografado (dado sensível)
    whatsapp_encrypted BYTEA NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_professionals_specialty ON public.professionals(specialty_id);
CREATE INDEX idx_professionals_active ON public.professionals(is_active);

-- ============================================================
-- 4. PLANS (Planos de assinatura)
-- ============================================================

CREATE TABLE public.plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    subscription_type subscription_type NOT NULL,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    discount_label TEXT,  -- ex: '30% Off'
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_plans_active ON public.plans(is_active);

-- ============================================================
-- 4.1 PLAN_BENEFITS (Benefícios do plano - normalizado)
-- ============================================================

CREATE TABLE public.plan_benefits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_plan_benefits_plan ON public.plan_benefits(plan_id);

-- ============================================================
-- 5. SUBSCRIPTIONS (Assinaturas de usuários)
-- ============================================================

CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE RESTRICT,
    badge_level badge_level NOT NULL DEFAULT 'bronze',
    plan_level_status plan_level_status NOT NULL DEFAULT 'bronze',
    activation_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expiration_date TIMESTAMPTZ,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason_id UUID,  -- FK adicionada após criação da tabela
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Apenas uma assinatura ativa por usuário
    CONSTRAINT uq_user_active_subscription UNIQUE (user_id, is_current)
        -- Parcial: só se is_current = true
);

-- Índice parcial para garantir uma assinatura ativa por usuário
CREATE UNIQUE INDEX idx_one_active_subscription
    ON public.subscriptions(user_id) WHERE is_current = TRUE;

CREATE INDEX idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX idx_subscriptions_plan ON public.subscriptions(plan_id);
CREATE INDEX idx_subscriptions_active ON public.subscriptions(is_current);

-- ============================================================
-- 6. BADGES (Configuração dos níveis de badge)
-- ============================================================

CREATE TABLE public.badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    level_name badge_level NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    badge_image_url TEXT,
    progress_color INTEGER NOT NULL DEFAULT 0,
    progress_bg_color INTEGER NOT NULL DEFAULT 0,
    sort_order INTEGER NOT NULL DEFAULT 0,
    discount_percentage NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    max_consultations_per_month INTEGER NOT NULL DEFAULT 0,
    -- Requisitos para alcançar este badge
    required_months INTEGER NOT NULL DEFAULT 0,
    required_consultations INTEGER NOT NULL DEFAULT 0,
    required_referrals INTEGER NOT NULL DEFAULT 0,
    requires_annual_plan BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 7. BADGE_PROGRESS (Progresso do usuário nos badges)
-- ============================================================

CREATE TABLE public.badge_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    current_badge_level badge_level NOT NULL DEFAULT 'bronze',
    consultation_count INTEGER NOT NULL DEFAULT 0 CHECK (consultation_count >= 0),
    referral_count INTEGER NOT NULL DEFAULT 0 CHECK (referral_count >= 0),
    plan_activation_date TIMESTAMPTZ,
    has_annual_plan BOOLEAN NOT NULL DEFAULT FALSE,
    last_upgrade_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_badge_progress_user ON public.badge_progress(user_id);
CREATE INDEX idx_badge_progress_level ON public.badge_progress(current_badge_level);

-- ============================================================
-- 8. CONSULTATIONS (Consultas agendadas)
-- ============================================================

CREATE TABLE public.consultations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    professional_id UUID NOT NULL REFERENCES public.professionals(id) ON DELETE RESTRICT,
    title TEXT NOT NULL,
    subtitle TEXT,
    scheduled_date TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'agendada'
        CHECK (status IN ('agendada', 'realizada', 'cancelada', 'remarcada')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_consultations_user ON public.consultations(user_id);
CREATE INDEX idx_consultations_professional ON public.consultations(professional_id);
CREATE INDEX idx_consultations_date ON public.consultations(scheduled_date);
CREATE INDEX idx_consultations_status ON public.consultations(status);

-- ============================================================
-- 9. PAYMENTS (Pagamentos)
-- ============================================================

CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    method payment_method NOT NULL,
    status payment_status NOT NULL DEFAULT 'pendente',
    receipt_number TEXT NOT NULL UNIQUE,
    paid_at TIMESTAMPTZ,
    -- Dados de cartão criptografados (quando aplicável)
    card_last_four_encrypted BYTEA,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_user ON public.payments(user_id);
CREATE INDEX idx_payments_subscription ON public.payments(subscription_id);
CREATE INDEX idx_payments_status ON public.payments(status);
CREATE INDEX idx_payments_receipt ON public.payments(receipt_number);
CREATE INDEX idx_payments_date ON public.payments(paid_at);

-- ============================================================
-- 10. COUPONS (Cupons de desconto)
-- ============================================================

CREATE TABLE public.coupons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    discount_percentage NUMERIC(5,2) NOT NULL CHECK (discount_percentage > 0 AND discount_percentage <= 100),
    expiry_date TIMESTAMPTZ NOT NULL,
    usage_limit INTEGER NOT NULL DEFAULT 0 CHECK (usage_limit >= 0),
    used_count INTEGER NOT NULL DEFAULT 0 CHECK (used_count >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_usage_limit CHECK (used_count <= usage_limit OR usage_limit = 0)
);

CREATE INDEX idx_coupons_code ON public.coupons(code);
CREATE INDEX idx_coupons_active ON public.coupons(is_active);
CREATE INDEX idx_coupons_expiry ON public.coupons(expiry_date);

-- ============================================================
-- 10.1 COUPON_USAGES (Uso de cupons - rastreabilidade)
-- ============================================================

CREATE TABLE public.coupon_usages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coupon_id UUID NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    payment_id UUID REFERENCES public.payments(id) ON DELETE SET NULL,
    used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Cada usuário usa um cupom apenas uma vez
    CONSTRAINT uq_coupon_user UNIQUE (coupon_id, user_id)
);

CREATE INDEX idx_coupon_usages_coupon ON public.coupon_usages(coupon_id);
CREATE INDEX idx_coupon_usages_user ON public.coupon_usages(user_id);

-- ============================================================
-- 11. DRAWS (Sorteios)
-- ============================================================

CREATE TABLE public.draws (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    prize_name TEXT NOT NULL,
    prize_description TEXT,
    prize_image_url TEXT,
    draw_date TIMESTAMPTZ NOT NULL,
    registration_start_date TIMESTAMPTZ,
    registration_end_date TIMESTAMPTZ,
    status draw_status NOT NULL DEFAULT 'agendado',
    participant_count INTEGER NOT NULL DEFAULT 0 CHECK (participant_count >= 0),
    winner_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    eligible_plan_levels badge_level[] DEFAULT '{}',  -- vazio = todos elegíveis
    rules TEXT,
    -- Campos de transparência do sorteio (auditoria)
    draw_seed_hash TEXT,        -- SHA-256 do seed usado
    participant_list_hash TEXT,  -- SHA-256 da lista de participantes
    executed_at TIMESTAMPTZ,
    winner_index INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_draws_status ON public.draws(status);
CREATE INDEX idx_draws_date ON public.draws(draw_date);
CREATE INDEX idx_draws_winner ON public.draws(winner_id);

-- ============================================================
-- 11.1 DRAW_PARTICIPANTS (Participantes dos sorteios)
-- ============================================================

CREATE TABLE public.draw_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    draw_id UUID NOT NULL REFERENCES public.draws(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Cada usuário participa uma vez por sorteio
    CONSTRAINT uq_draw_participant UNIQUE (draw_id, user_id)
);

CREATE INDEX idx_draw_participants_draw ON public.draw_participants(draw_id);
CREATE INDEX idx_draw_participants_user ON public.draw_participants(user_id);

-- ============================================================
-- 12. REFERRALS (Indicações)
-- ============================================================

CREATE TABLE public.referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    referred_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    referral_code TEXT NOT NULL UNIQUE,
    status referral_status NOT NULL DEFAULT 'pending',
    referred_completed_consultation BOOLEAN NOT NULL DEFAULT FALSE,
    activated_at TIMESTAMPTZ,
    reward_claimed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX idx_referrals_referred ON public.referrals(referred_id);
CREATE INDEX idx_referrals_code ON public.referrals(referral_code);
CREATE INDEX idx_referrals_status ON public.referrals(status);

-- ============================================================
-- 13. NOTIFICATION_TEMPLATES (Templates de notificação)
-- ============================================================

CREATE TABLE public.notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type notification_type NOT NULL,
    trigger_event TEXT NOT NULL,  -- ex: 'draw_created', 'coupon_assigned'
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_templates_type ON public.notification_templates(type);
CREATE INDEX idx_notification_templates_active ON public.notification_templates(is_active);
CREATE INDEX idx_notification_templates_trigger ON public.notification_templates(trigger_event);

-- ============================================================
-- 13.1 NOTIFICATIONS (Notificações enviadas aos usuários)
-- ============================================================

CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    template_id UUID REFERENCES public.notification_templates(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type notification_type NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    data JSONB,  -- payload extra (ex: draw_id, coupon_id)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_read ON public.notifications(is_read);
CREATE INDEX idx_notifications_type ON public.notifications(type);
CREATE INDEX idx_notifications_created ON public.notifications(created_at DESC);

-- ============================================================
-- 14. CANCELLATION_REASONS (Motivos de cancelamento)
-- ============================================================

CREATE TABLE public.cancellation_reasons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    text TEXT NOT NULL UNIQUE,
    usage_count INTEGER NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 15. AUDIT_LOG (Log de auditoria para ACID/compliance)
-- ============================================================

CREATE TABLE public.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data JSONB,
    new_data JSONB,
    performed_by UUID REFERENCES auth.users(id),
    performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address INET
);

CREATE INDEX idx_audit_table ON public.audit_log(table_name);
CREATE INDEX idx_audit_record ON public.audit_log(record_id);
CREATE INDEX idx_audit_action ON public.audit_log(action);
CREATE INDEX idx_audit_date ON public.audit_log(performed_at DESC);

-- ============================================================
-- FK RETROATIVA: subscription → cancellation_reason
-- ============================================================

ALTER TABLE public.subscriptions
    ADD CONSTRAINT fk_cancellation_reason
    FOREIGN KEY (cancellation_reason_id)
    REFERENCES public.cancellation_reasons(id)
    ON DELETE SET NULL;

-- ============================================================
-- FUNCTIONS: Criptografia de dados sensíveis
-- ============================================================

-- Chave simétrica armazenada no Supabase Vault (nunca exposta)
-- No Supabase Dashboard: Settings > Vault > criar secret 'vita_clube_encryption_key'

-- Função para criptografar CPF
CREATE OR REPLACE FUNCTION encrypt_cpf(raw_cpf TEXT)
RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(
        raw_cpf,
        current_setting('app.encryption_key')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para descriptografar CPF
CREATE OR REPLACE FUNCTION decrypt_cpf(encrypted_cpf BYTEA)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(
        encrypted_cpf,
        current_setting('app.encryption_key')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para gerar hash do CPF (busca sem descriptografar)
CREATE OR REPLACE FUNCTION hash_cpf(raw_cpf TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN encode(digest(raw_cpf, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função genérica para criptografar (telefone, whatsapp, etc)
CREATE OR REPLACE FUNCTION encrypt_sensitive(raw_text TEXT)
RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(
        raw_text,
        current_setting('app.encryption_key')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função genérica para descriptografar
CREATE OR REPLACE FUNCTION decrypt_sensitive(encrypted_data BYTEA)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(
        encrypted_data,
        current_setting('app.encryption_key')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- TRIGGERS: updated_at automático
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a todas as tabelas com updated_at
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN
        SELECT table_name FROM information_schema.columns
        WHERE column_name = 'updated_at'
        AND table_schema = 'public'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.%I
             FOR EACH ROW EXECUTE FUNCTION update_updated_at()',
            t
        );
    END LOOP;
END;
$$;

-- ============================================================
-- TRIGGER: Auditoria automática
-- ============================================================

CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.audit_log (table_name, record_id, action, new_data, performed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW), auth.uid());
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.audit_log (table_name, record_id, action, old_data, new_data, performed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), auth.uid());
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO public.audit_log (table_name, record_id, action, old_data, performed_by)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), auth.uid());
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Tabelas auditadas (sensíveis)
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN VALUES
        ('payments'), ('subscriptions'), ('draws'),
        ('referrals'), ('coupons'), ('profiles')
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_audit AFTER INSERT OR UPDATE OR DELETE ON public.%I
             FOR EACH ROW EXECUTE FUNCTION audit_trigger_func()',
            t
        );
    END LOOP;
END;
$$;

-- ============================================================
-- TRIGGER: Incrementar used_count do cupom ao usar
-- ============================================================

CREATE OR REPLACE FUNCTION increment_coupon_usage()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.coupons
    SET used_count = used_count + 1
    WHERE id = NEW.coupon_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_coupon_usage
    AFTER INSERT ON public.coupon_usages
    FOR EACH ROW EXECUTE FUNCTION increment_coupon_usage();

-- ============================================================
-- TRIGGER: Incrementar participant_count do sorteio
-- ============================================================

CREATE OR REPLACE FUNCTION update_draw_participant_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.draws SET participant_count = participant_count + 1
        WHERE id = NEW.draw_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.draws SET participant_count = participant_count - 1
        WHERE id = OLD.draw_id;
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_draw_participants
    AFTER INSERT OR DELETE ON public.draw_participants
    FOR EACH ROW EXECUTE FUNCTION update_draw_participant_count();

-- ============================================================
-- TRIGGER: Criar badge_progress ao criar profile
-- ============================================================

CREATE OR REPLACE FUNCTION create_badge_progress_on_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.badge_progress (user_id, current_badge_level)
    VALUES (NEW.id, 'bronze');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_badge_progress
    AFTER INSERT ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION create_badge_progress_on_profile();

-- ============================================================
-- RLS (Row Level Security) - Segurança por linha
-- ============================================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.specialties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.professionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_benefits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badge_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupon_usages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.draws ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.draw_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cancellation_reasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- Helper: checar se é admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Helper: checar se é financeiro
CREATE OR REPLACE FUNCTION is_financeiro()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'financeiro'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ── PROFILES ──
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
    ON public.profiles FOR SELECT
    USING (is_admin());

CREATE POLICY "Financeiro can view profiles"
    ON public.profiles FOR SELECT
    USING (is_financeiro());

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can manage all profiles"
    ON public.profiles FOR ALL
    USING (is_admin());

-- ── SPECIALTIES (público para leitura) ──
CREATE POLICY "Anyone can view active specialties"
    ON public.specialties FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Admins can manage specialties"
    ON public.specialties FOR ALL
    USING (is_admin());

-- ── PROFESSIONALS (público para leitura) ──
CREATE POLICY "Anyone can view active professionals"
    ON public.professionals FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Admins can manage professionals"
    ON public.professionals FOR ALL
    USING (is_admin());

-- ── PLANS (público para leitura) ──
CREATE POLICY "Anyone can view active plans"
    ON public.plans FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Admins can manage plans"
    ON public.plans FOR ALL
    USING (is_admin());

-- ── PLAN_BENEFITS ──
CREATE POLICY "Anyone can view plan benefits"
    ON public.plan_benefits FOR SELECT
    USING (TRUE);

CREATE POLICY "Admins can manage plan benefits"
    ON public.plan_benefits FOR ALL
    USING (is_admin());

-- ── SUBSCRIPTIONS ──
CREATE POLICY "Users can view own subscriptions"
    ON public.subscriptions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all subscriptions"
    ON public.subscriptions FOR ALL
    USING (is_admin());

CREATE POLICY "Financeiro can view all subscriptions"
    ON public.subscriptions FOR SELECT
    USING (is_financeiro());

-- ── BADGES (público para leitura) ──
CREATE POLICY "Anyone can view badges"
    ON public.badges FOR SELECT
    USING (TRUE);

CREATE POLICY "Admins can manage badges"
    ON public.badges FOR ALL
    USING (is_admin());

-- ── BADGE_PROGRESS ──
CREATE POLICY "Users can view own badge progress"
    ON public.badge_progress FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage badge progress"
    ON public.badge_progress FOR ALL
    USING (is_admin());

-- ── CONSULTATIONS ──
CREATE POLICY "Users can view own consultations"
    ON public.consultations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own consultations"
    ON public.consultations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage all consultations"
    ON public.consultations FOR ALL
    USING (is_admin());

-- ── PAYMENTS ──
CREATE POLICY "Users can view own payments"
    ON public.payments FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all payments"
    ON public.payments FOR ALL
    USING (is_admin());

CREATE POLICY "Financeiro can view all payments"
    ON public.payments FOR SELECT
    USING (is_financeiro());

-- ── COUPONS (público para leitura de ativos) ──
CREATE POLICY "Anyone can view active coupons"
    ON public.coupons FOR SELECT
    USING (is_active = TRUE AND expiry_date > NOW());

CREATE POLICY "Admins can manage coupons"
    ON public.coupons FOR ALL
    USING (is_admin());

CREATE POLICY "Financeiro can view all coupons"
    ON public.coupons FOR SELECT
    USING (is_financeiro());

-- ── COUPON_USAGES ──
CREATE POLICY "Users can view own coupon usages"
    ON public.coupon_usages FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can use coupons"
    ON public.coupon_usages FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage coupon usages"
    ON public.coupon_usages FOR ALL
    USING (is_admin());

-- ── DRAWS ──
CREATE POLICY "Anyone can view draws"
    ON public.draws FOR SELECT
    USING (TRUE);

CREATE POLICY "Admins can manage draws"
    ON public.draws FOR ALL
    USING (is_admin());

-- ── DRAW_PARTICIPANTS ──
CREATE POLICY "Users can view own participations"
    ON public.draw_participants FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can register for draws"
    ON public.draw_participants FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage draw participants"
    ON public.draw_participants FOR ALL
    USING (is_admin());

-- ── REFERRALS ──
CREATE POLICY "Users can view own referrals"
    ON public.referrals FOR SELECT
    USING (auth.uid() = referrer_id OR auth.uid() = referred_id);

CREATE POLICY "Users can create referrals"
    ON public.referrals FOR INSERT
    WITH CHECK (auth.uid() = referrer_id);

CREATE POLICY "Admins can manage referrals"
    ON public.referrals FOR ALL
    USING (is_admin());

-- ── NOTIFICATION_TEMPLATES ──
CREATE POLICY "Admins can manage notification templates"
    ON public.notification_templates FOR ALL
    USING (is_admin());

-- ── NOTIFICATIONS ──
CREATE POLICY "Users can view own notifications"
    ON public.notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can mark own notifications as read"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage notifications"
    ON public.notifications FOR ALL
    USING (is_admin());

-- ── CANCELLATION_REASONS ──
CREATE POLICY "Anyone can view active reasons"
    ON public.cancellation_reasons FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Admins can manage cancellation reasons"
    ON public.cancellation_reasons FOR ALL
    USING (is_admin());

-- ── AUDIT_LOG (somente admin lê) ──
CREATE POLICY "Admins can view audit log"
    ON public.audit_log FOR SELECT
    USING (is_admin());

-- ============================================================
-- FUNCTION: Executar sorteio com transparência (ACID)
-- ============================================================

CREATE OR REPLACE FUNCTION execute_draw(draw_id UUID, seed TEXT)
RETURNS UUID AS $$
DECLARE
    v_participant_ids UUID[];
    v_participant_count INTEGER;
    v_winner_index INTEGER;
    v_winner_id UUID;
    v_seed_hash TEXT;
    v_participant_hash TEXT;
BEGIN
    -- Verificar status do sorteio
    IF NOT EXISTS (
        SELECT 1 FROM public.draws
        WHERE id = draw_id AND status = 'inscricoes_encerradas'
    ) THEN
        RAISE EXCEPTION 'Sorteio não está pronto para execução';
    END IF;

    -- Buscar participantes ordenados por ID (determinístico)
    SELECT ARRAY_AGG(user_id ORDER BY user_id)
    INTO v_participant_ids
    FROM public.draw_participants
    WHERE draw_participants.draw_id = execute_draw.draw_id;

    v_participant_count := array_length(v_participant_ids, 1);

    IF v_participant_count IS NULL OR v_participant_count = 0 THEN
        RAISE EXCEPTION 'Nenhum participante registrado';
    END IF;

    -- Gerar hashes para transparência
    v_seed_hash := encode(digest(seed, 'sha256'), 'hex');
    v_participant_hash := encode(digest(array_to_string(v_participant_ids, ','), 'sha256'), 'hex');

    -- Selecionar vencedor deterministicamente pelo seed
    v_winner_index := abs(('x' || substring(v_seed_hash, 1, 8))::bit(32)::integer) % v_participant_count;
    v_winner_id := v_participant_ids[v_winner_index + 1]; -- arrays PG começam em 1

    -- Atualizar sorteio atomicamente
    UPDATE public.draws SET
        status = 'realizado',
        winner_id = v_winner_id,
        draw_seed_hash = v_seed_hash,
        participant_list_hash = v_participant_hash,
        executed_at = NOW(),
        winner_index = v_winner_index
    WHERE id = draw_id;

    RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- FUNCTION: Criar perfil automaticamente após signup
-- ============================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_cpf   TEXT := NULLIF(NEW.raw_user_meta_data->>'cpf', '');
    v_phone TEXT := NULLIF(NEW.raw_user_meta_data->>'phone', '');
    v_name  TEXT := COALESCE(
        NULLIF(NEW.raw_user_meta_data->>'name', ''),
        NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
        split_part(NEW.email, '@', 1)
    );
BEGIN
    INSERT INTO public.profiles (
        id, name, email, cpf_encrypted, cpf_hash, phone_encrypted, role, avatar_url
    )
    VALUES (
        NEW.id,
        v_name,
        NEW.email,
        CASE WHEN v_cpf   IS NOT NULL THEN encrypt_sensitive(v_cpf) END,
        CASE WHEN v_cpf   IS NOT NULL THEN hash_cpf(v_cpf)         END,
        CASE WHEN v_phone IS NOT NULL THEN encrypt_sensitive(v_phone) END,
        'user',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'handle_new_user failed for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- VIEWS (para facilitar queries no Flutter)
-- ============================================================

-- View: Consultas com nomes de profissional e especialidade
CREATE OR REPLACE VIEW public.v_consultations AS
SELECT
    c.id,
    c.user_id,
    c.title,
    c.subtitle,
    c.scheduled_date,
    c.status,
    c.notes,
    p.id AS professional_id,
    p.name AS professional_name,
    s.name AS specialty_name,
    c.created_at
FROM public.consultations c
JOIN public.professionals p ON c.professional_id = p.id
JOIN public.specialties s ON p.specialty_id = s.id;

-- View: Pagamentos com nome do usuário e plano
CREATE OR REPLACE VIEW public.v_payments AS
SELECT
    pay.id,
    pay.user_id,
    prof.name AS user_name,
    pay.amount,
    pay.method,
    pay.status,
    pay.receipt_number,
    pay.paid_at,
    pl.name AS plan_name,
    pl.subscription_type AS subscription_type,
    pay.created_at
FROM public.payments pay
JOIN public.profiles prof ON pay.user_id = prof.id
LEFT JOIN public.subscriptions sub ON pay.subscription_id = sub.id
LEFT JOIN public.plans pl ON sub.plan_id = pl.id;

-- ============================================================
-- SEED DATA: Dados iniciais (badges, especialidades)
-- ============================================================

-- Badges padrão
INSERT INTO public.badges (level_name, display_name, badge_image_url, sort_order,
    discount_percentage, max_consultations_per_month,
    required_months, required_consultations, required_referrals, requires_annual_plan,
    progress_color, progress_bg_color)
VALUES
    ('bronze', 'Bronze', NULL, 1, 0, 2, 0, 0, 0, FALSE, 4291288124, 4292927981),
    ('prata', 'Prata', NULL, 2, 5, 4, 6, 4, 0, FALSE, 4290822336, 4293322472),
    ('ouro', 'Ouro', NULL, 3, 10, 6, 12, 6, 2, FALSE, 4294956800, 4294963409),
    ('diamante', 'Diamante', NULL, 4, 15, 10, 24, 14, 3, TRUE, 4290362367, 4293525503);

-- Especialidades padrão
INSERT INTO public.specialties (name) VALUES
    ('Clínico Geral'),
    ('Pediatria'),
    ('Dermatologia'),
    ('Ortopedia'),
    ('Cardiologia'),
    ('Ginecologia'),
    ('Oftalmologia'),
    ('Neurologia'),
    ('Psiquiatria'),
    ('Nutrição');

-- Motivos de cancelamento padrão
INSERT INTO public.cancellation_reasons (text) VALUES
    ('Valor muito alto'),
    ('Não uso o suficiente'),
    ('Encontrei alternativa melhor'),
    ('Problemas com atendimento'),
    ('Mudança de cidade');

-- ============================================================
-- 16. PARTNERS (Parceiros - labs, clinicas, farmacias)
-- ============================================================

CREATE TYPE partner_category AS ENUM ('laboratorio', 'clinica', 'farmacia', 'otica', 'outro');

CREATE TABLE public.partners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category partner_category NOT NULL,
    code TEXT NOT NULL UNIQUE,
    address TEXT,
    phone_encrypted BYTEA,
    logo_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_partners_profile ON public.partners(profile_id);
CREATE INDEX idx_partners_category ON public.partners(category);
CREATE INDEX idx_partners_code ON public.partners(code);
CREATE INDEX idx_partners_active ON public.partners(is_active);

-- ============================================================
-- 16.1 PARTNER_SERVICES (Servicos dos parceiros)
-- ============================================================

CREATE TABLE public.partner_services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    partner_id UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    original_price NUMERIC(10,2) NOT NULL CHECK (original_price >= 0),
    discounted_price NUMERIC(10,2) NOT NULL CHECK (discounted_price >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_partner_services_partner ON public.partner_services(partner_id);
CREATE INDEX idx_partner_services_active ON public.partner_services(is_active);

-- ============================================================
-- 16.2 PARTNER_VALIDATIONS (Validacoes de desconto)
-- ============================================================

CREATE TABLE public.partner_validations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    partner_id UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    service_id UUID REFERENCES public.partner_services(id) ON DELETE SET NULL,
    user_name TEXT NOT NULL,
    user_badge_level TEXT NOT NULL DEFAULT 'bronze',
    discount_applied NUMERIC(10,2) NOT NULL DEFAULT 0,
    service_name TEXT NOT NULL,
    validated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_partner_validations_partner ON public.partner_validations(partner_id);
CREATE INDEX idx_partner_validations_user ON public.partner_validations(user_id);
CREATE INDEX idx_partner_validations_date ON public.partner_validations(validated_at DESC);

-- RLS para partners
ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_validations ENABLE ROW LEVEL SECURITY;

-- Helper: checar se é parceiro
CREATE OR REPLACE FUNCTION is_parceiro()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'parceiro'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ── PARTNERS ──
CREATE POLICY "Parceiros can view own partner"
    ON public.partners FOR SELECT
    USING (profile_id = auth.uid());

CREATE POLICY "Parceiros can update own partner"
    ON public.partners FOR UPDATE
    USING (profile_id = auth.uid())
    WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can view active partners"
    ON public.partners FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Admins can manage partners"
    ON public.partners FOR ALL
    USING (is_admin());

-- ── PARTNER_SERVICES ──
CREATE POLICY "Parceiros can manage own services"
    ON public.partner_services FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.partners
            WHERE partners.id = partner_services.partner_id
            AND partners.profile_id = auth.uid()
        )
    );

CREATE POLICY "Users can view active partner services"
    ON public.partner_services FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Admins can manage partner services"
    ON public.partner_services FOR ALL
    USING (is_admin());

-- ── PARTNER_VALIDATIONS ──
CREATE POLICY "Parceiros can view own validations"
    ON public.partner_validations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.partners
            WHERE partners.id = partner_validations.partner_id
            AND partners.profile_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage partner validations"
    ON public.partner_validations FOR ALL
    USING (is_admin());
