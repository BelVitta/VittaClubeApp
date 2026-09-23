-- Garante que cada ambiente tenha a oferta mensal publicada.
-- Não substitui alterações feitas pelo financeiro e não duplica a oferta.

insert into public.plans (
  name, subscription_type, price, discount_label, is_active
)
select 'Vita Mensal', 'mensal', 34.90, null, true
where not exists (
  select 1 from public.plans where subscription_type = 'mensal'
);

insert into public.plan_benefits (plan_id, title, description, sort_order)
select p.id, benefit.title, benefit.description, benefit.sort_order
  from public.plans p
 cross join (values
   ('Descontos progressivos', 'Sua patente libera descontos em consultas elegíveis.', 1),
   ('Jornada de patentes', 'Cada mensalidade aprovada aproxima você do próximo nível.', 2),
   ('Sorteios exclusivos', 'Sua patente define quantos sorteios você pode escolher por ano.', 3),
   ('Sem permanência mínima', 'Cancele quando quiser e preserve o progresso dos meses pagos.', 4)
 ) as benefit(title, description, sort_order)
 where p.subscription_type = 'mensal'
   and not exists (
     select 1 from public.plan_benefits b
      where b.plan_id = p.id and b.title = benefit.title
   );
