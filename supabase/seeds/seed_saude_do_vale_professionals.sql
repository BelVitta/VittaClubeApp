-- =============================================================================
-- Seed: profissionais da clínica Saúde do Vale (Russas/CE)
-- Fonte: coleta de implantação (COLETA DE DADOS PADRÃO - Sistema)
--
-- Tabelas: public.specialties, public.professionals
-- Campos da tabela professionals: name, specialty_id, available_days,
--   availability_note, whatsapp_encrypted, is_active, avatar_bg_color
-- NÃO há colunas de CPF, e-mail, conselho ou preço de consulta no schema.
--
-- Como rodar: Supabase Dashboard → SQL Editor → colar e executar (como postgres
-- ou service_role). Pode reexecutar: usa ON CONFLICT / NOT EXISTS.
--
-- WhatsApp: o admin do app grava bytes UTF-8 (não pgp). Mantemos o mesmo
-- padrão com convert_to(..., 'UTF8') para compatibilidade com o app.
-- Formato do número: 55 + DDD + celular (somente dígitos).
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1) Especialidades
-- ---------------------------------------------------------------------------
INSERT INTO public.specialties (name, is_active)
VALUES
  ('Otorrinolaringologia', TRUE),
  ('Psicologia', TRUE),
  ('Psicologia Clínica', TRUE),
  ('Psicologia Infanto-juvenil', TRUE),
  ('Fisioterapia', TRUE),
  ('Geriatria e Gerontologia', TRUE),
  ('Dermatologia', TRUE),
  ('Urologia', TRUE),
  ('Clínica Geral', TRUE),
  ('Neurologia', TRUE),
  ('Enfermagem Ginecológica', TRUE),
  ('Pneumologia', TRUE),
  ('Nutrição', TRUE),
  ('Fonoaudiologia', TRUE)
ON CONFLICT (name) DO UPDATE
SET is_active = EXCLUDED.is_active,
    updated_at = NOW();

-- ---------------------------------------------------------------------------
-- 2) Profissionais
--    available_days: seg | ter | qua | qui | sex | sab | dom
--    availability_note: horários irregulares / valores / procedimentos
-- ---------------------------------------------------------------------------

-- Helper local: evita duplicar pelo nome (case-insensitive)
-- Se já existir um profissional com o mesmo nome, o INSERT é ignorado.

INSERT INTO public.professionals (
  name,
  specialty_id,
  available_days,
  availability_note,
  whatsapp_encrypted,
  avatar_bg_color,
  is_active
)
SELECT
  v.name,
  s.id,
  v.available_days,
  v.availability_note,
  convert_to(v.whatsapp, 'UTF8'),
  v.avatar_bg_color,
  TRUE
FROM (
  VALUES
    -- 1) Dr. Vinicius Belchior — ORL
    (
      'Dr. Vinicius Belchior Lima',
      'Otorrinolaringologia',
      ARRAY['ter']::text[],
      'Terça à tarde. Consultas, laringoscopia e nasofibroscopia. Consulta R$250 à vista/PIX ou R$300 cartão até 3x. Exames R$300 à vista/PIX ou R$350 cartão até 3x.',
      '5585984302010',
      0
    ),
    -- 2) Gabriela Teixeira — Psicologia / forense
    (
      'Gabriela Alves Teixeira',
      'Psicologia',
      ARRAY['qua', 'sex']::text[],
      'Qua 17h10 e sex 15h00. Investigação criminal, psicologia forense, clínica e psicossocial. Atendimento R$120 à vista/PIX.',
      '5585985057435',
      1
    ),
    -- 3) Elisangela Xavier — Fisioterapia
    (
      'Elisangela Xavier Santiago',
      'Fisioterapia',
      ARRAY[]::text[],
      'Fisioterapia, respiratória, RPG, Pilates, isostretching e liberação miofascial. Valor R$170. Grade a combinar.',
      '558896108674',
      2
    ),
    -- 4) Judith Soraia — Psicologia Clínica
    (
      'Judith Soraia Sampaio de Lima',
      'Psicologia Clínica',
      ARRAY['qua']::text[],
      'Quartas às 18h e 19h. Consulta R$100 à vista/PIX.',
      '5588981304864',
      3
    ),
    -- 5) Bianca Lira — Psicologia
    (
      'Bianca Lira Araújo Freire',
      'Psicologia',
      ARRAY[]::text[],
      'Atendimento com horário marcado. Valor R$100 à vista/PIX.',
      '5588992230213',
      4
    ),
    -- 6) Fernanda Queirós — Psicologia
    (
      'Fernanda Fernandes Queirós',
      'Psicologia',
      ARRAY['qui', 'sex']::text[],
      'Qui dia todo; sex manhã. Psicoterapia (criança, adolescente, adulto e idoso). Consulta R$170 à vista.',
      '5588981936556',
      5
    ),
    -- 7) Dr. Klewton Batista — Geriatria (sem celular no formulário)
    (
      'Dr. Luis Klewton de Oliveira Batista',
      'Geriatria e Gerontologia',
      ARRAY['qui']::text[],
      'Quintas quinzenais. Consulta R$500 à vista/PIX. Contato via clínica.',
      '5588981324972',
      0
    ),
    -- 8) Dr. Adriano Accioly — Dermatologia
    (
      'Dr. Adriano Adeodato Accioly',
      'Dermatologia',
      ARRAY['ter']::text[],
      'Terças quinzenais, 7h30–9h. Adultos e crianças (sem pequenas cirurgias por enquanto). Consulta R$300 à vista/PIX.',
      '5585988001804',
      1
    ),
    -- 9) Dr. Ângelo Figueiredo — Urologia
    (
      'Dr. Ângelo Cunha de Figueiredo Filho',
      'Urologia',
      ARRAY['ter', 'sex']::text[],
      'Ter e sex, 2x/mês (consultar agenda). Uro-oncologia, próstata, andrologia, cálculos e cirurgia minimamente invasiva. Consulta R$300 à vista/PIX.',
      '558587730419',
      2
    ),
    -- 10) Dr. Raul Arrais — Clínica Geral
    (
      'Dr. Raul Luís Barreto Arrais',
      'Clínica Geral',
      ARRAY['seg', 'ter', 'qui', 'sex']::text[],
      'Seg/qui/sex 18h; ter 15h. Consulta R$200 à vista.',
      '5588996892064',
      3
    ),
    -- 11) Dr. Wedney Livânio — Neurologia
    (
      'Dr. Wedney Livanio de Sousa Santos',
      'Neurologia',
      ARRAY[]::text[],
      'Cerca de 1x por mês, conforme agenda. Consulta R$450 à vista/PIX. Exame R$400.',
      '558491674994',
      4
    ),
    -- 12) Marcela Matos — Psicologia Infanto-juvenil
    (
      'Francisca Marcela de M. Fonseca',
      'Psicologia Infanto-juvenil',
      ARRAY['qui', 'sex']::text[],
      'Qui 11h–19h; sex 8h–15h. Atendimento R$170 à vista/PIX.',
      '5585996385444',
      5
    ),
    -- 13) Cecília Gifoni — Enfermagem ginecológica
    (
      'Cecilia Juliete Gifoni Marreiro',
      'Enfermagem Ginecológica',
      ARRAY['ter', 'sex']::text[],
      'Ter a partir de 18h; sex a partir de 16h. Consulta R$150 (prevenção inclusa). Procedimentos: prevenção em meio líquido, genotipagem HPV, inserção de Implanon.',
      '5588999308987',
      0
    ),
    -- 14) Dr. Lucca Drebes — Pneumologia
    (
      'Dr. Lucca Drebes',
      'Pneumologia',
      ARRAY['qui']::text[],
      'Quinta à tarde, quinzenal. Sem procedimentos. Consulta R$300 à vista.',
      '5585989335184',
      1
    ),
    -- 15) Daiana Oliveira — Nutrição
    (
      'Daiana Mara Oliveira Pereira',
      'Nutrição',
      ARRAY[]::text[],
      'Nutrição clínica funcional. Consulta R$250 à vista. Grade a combinar.',
      '558599824220',
      2
    ),
    -- 16) Raimunda / Liduina Santos — Fonoaudiologia
    (
      'Raimunda Francisca dos Santos',
      'Fonoaudiologia',
      ARRAY['seg', 'qua', 'sab']::text[],
      'Seg e qua a partir de 17h; sáb a partir de 7h. Avaliação R$180 à vista; sessões R$90–100.',
      '558599824220',
      3
    ),
    -- 17) Mariana Leite — Psicologia
    (
      'Mariana Silva Leite',
      'Psicologia',
      ARRAY[]::text[],
      'Conforme agenda da profissional. Atendimento R$100 à vista/PIX.',
      '5588999385655',
      4
    ),
    -- 18) Paulo Madson — Fonoaudiologia / Audiometria
    (
      'Paulo Madson Dutra de Moura',
      'Fonoaudiologia',
      ARRAY[]::text[],
      'Audiometria R$150; imitanciometria R$100 à vista ou cartão até 3x. Grade a combinar.',
      '5585986829536',
      5
    )
) AS v(
  name,
  specialty_name,
  available_days,
  availability_note,
  whatsapp,
  avatar_bg_color
)
JOIN public.specialties s ON s.name = v.specialty_name
WHERE NOT EXISTS (
  SELECT 1
  FROM public.professionals p
  WHERE lower(trim(p.name)) = lower(trim(v.name))
);

COMMIT;

-- ---------------------------------------------------------------------------
-- Conferência
-- ---------------------------------------------------------------------------
SELECT
  p.name,
  s.name AS specialty,
  p.available_days,
  p.availability_note,
  convert_from(p.whatsapp_encrypted, 'UTF8') AS whatsapp,
  p.is_active
FROM public.professionals p
JOIN public.specialties s ON s.id = p.specialty_id
WHERE p.name IN (
  'Dr. Vinicius Belchior Lima',
  'Gabriela Alves Teixeira',
  'Elisangela Xavier Santiago',
  'Judith Soraia Sampaio de Lima',
  'Bianca Lira Araújo Freire',
  'Fernanda Fernandes Queirós',
  'Dr. Luis Klewton de Oliveira Batista',
  'Dr. Adriano Adeodato Accioly',
  'Dr. Ângelo Cunha de Figueiredo Filho',
  'Dr. Raul Luís Barreto Arrais',
  'Dr. Wedney Livanio de Sousa Santos',
  'Francisca Marcela de M. Fonseca',
  'Cecilia Juliete Gifoni Marreiro',
  'Dr. Lucca Drebes',
  'Daiana Mara Oliveira Pereira',
  'Raimunda Francisca dos Santos',
  'Mariana Silva Leite',
  'Paulo Madson Dutra de Moura'
)
ORDER BY s.name, p.name;
