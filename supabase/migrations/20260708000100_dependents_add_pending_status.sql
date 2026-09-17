-- Novo estado do dependente: precisa existir em transação própria antes de
-- ser usado (limitação do Postgres para ALTER TYPE ... ADD VALUE).
alter type public.dependent_status add value if not exists 'pending';
