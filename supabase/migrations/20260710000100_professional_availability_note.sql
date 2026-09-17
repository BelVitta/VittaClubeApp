-- Complementa available_days (dias fixos da semana) com um campo livre pra
-- casos que não cabem num conjunto de dias da semana (ex.: "atende 1x por
-- mês", "quinzenal, consultar recepção"). Quando preenchido, a UI mostra
-- essa observação no lugar da lista de dias.
alter table public.professionals
  add column if not exists availability_note text;
