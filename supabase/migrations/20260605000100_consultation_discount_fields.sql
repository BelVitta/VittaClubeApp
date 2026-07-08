-- ============================================================
-- Migration: campos de desconto em consultations
--
-- Objetivo:
--   1. Tornar professional_id opcional (consultas validadas pelo admin
--      via QR não exigem profissional pré-vinculado).
--   2. Adicionar status 'validada' para consultas registradas no scanner.
--   3. Adicionar colunas de valor e desconto para calcular a economia
--      do membro em cada consulta validada.
-- ============================================================

-- ── 1. Tornar professional_id opcional ───────────────────────
ALTER TABLE public.consultations
  ALTER COLUMN professional_id DROP NOT NULL;

-- ── 2. Ampliar o CHECK de status para incluir 'validada' ─────
-- Identifica e remove o constraint inline existente antes de recriar.
DO $$
DECLARE
  v_constraint TEXT;
BEGIN
  SELECT conname
    INTO v_constraint
    FROM pg_constraint
   WHERE conrelid = 'public.consultations'::regclass
     AND contype  = 'c'
     AND conname  LIKE '%status%'
   LIMIT 1;

  IF v_constraint IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.consultations DROP CONSTRAINT %I', v_constraint);
  END IF;
END $$;

ALTER TABLE public.consultations
  ADD CONSTRAINT consultations_status_check
  CHECK (status IN ('agendada', 'realizada', 'cancelada', 'remarcada', 'validada'));

-- ── 3. Colunas de desconto e rastreio de validação ───────────
ALTER TABLE public.consultations
  ADD COLUMN IF NOT EXISTS original_value      NUMERIC(10,2)
    CHECK (original_value IS NULL OR original_value >= 0),
  ADD COLUMN IF NOT EXISTS discount_percentage NUMERIC(5,2)
    CHECK (discount_percentage IS NULL OR (discount_percentage >= 0 AND discount_percentage <= 100)),
  ADD COLUMN IF NOT EXISTS discount_amount     NUMERIC(10,2)
    CHECK (discount_amount IS NULL OR discount_amount >= 0),
  ADD COLUMN IF NOT EXISTS final_value         NUMERIC(10,2)
    CHECK (final_value IS NULL OR final_value >= 0),
  ADD COLUMN IF NOT EXISTS validated_by        UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS validated_at        TIMESTAMPTZ;

-- ── 4. Índices para consultas de histórico e relatórios ──────
CREATE INDEX IF NOT EXISTS idx_consultations_validated_by
  ON public.consultations(validated_by)
  WHERE validated_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_consultations_validated_at
  ON public.consultations(validated_at DESC)
  WHERE validated_at IS NOT NULL;

-- Índice composto: histórico do membro ordenado por data
CREATE INDEX IF NOT EXISTS idx_consultations_user_validated_at
  ON public.consultations(user_id, validated_at DESC)
  WHERE validated_at IS NOT NULL;

-- ── 5. Comentários de documentação ───────────────────────────
COMMENT ON COLUMN public.consultations.original_value IS
  'Valor cheio da consulta informado pelo admin no momento da validação QR (em R$).';
COMMENT ON COLUMN public.consultations.discount_percentage IS
  'Percentual de desconto aplicado conforme o nível de badge do membro (ex: 15.00 = 15%).';
COMMENT ON COLUMN public.consultations.discount_amount IS
  'Valor em R$ do desconto concedido. Calculado: original_value * discount_percentage / 100.';
COMMENT ON COLUMN public.consultations.final_value IS
  'Valor final cobrado do membro após desconto. Calculado: original_value - discount_amount.';
COMMENT ON COLUMN public.consultations.validated_by IS
  'UUID do admin que validou a consulta via scanner QR.';
COMMENT ON COLUMN public.consultations.validated_at IS
  'Timestamp exato da validação pelo admin.';
