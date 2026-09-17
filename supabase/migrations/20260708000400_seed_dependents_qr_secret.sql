-- Semeia um segredo aleatório (gerado no próprio Postgres) para assinar o
-- QR de agendamento de dependentes (QrTokenService). Client-side apenas
-- torna o token opaco/difícil de adivinhar — a autorização real continua
-- sendo a RLS (insert só pelo próprio titular) + as checagens da RPC
-- validate_dependent_qr (assinatura ativa, dependente ativo, cota, janela).
insert into public.clinic_settings (key, value)
values (
  'dependents_qr_signing_secret',
  encode(gen_random_bytes(32), 'hex')
)
on conflict (key) do nothing;
