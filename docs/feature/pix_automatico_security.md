# Pix Automático Woovi - Checklist de segurança

## Segredos

- `WOOVI_APP_ID` fica apenas em Supabase secrets.
- `WOOVI_WEBHOOK_SECRET` fica apenas em Supabase secrets.
- Flutter não pode conter App ID, webhook secret ou base URL Woovi.
- Ambientes sandbox e produção usam secrets separados.

## Backend-only

- Flutter chama apenas Supabase Edge Functions.
- Edge Functions usam service role somente depois de validar autenticação/permissão quando há ação do usuário.
- Webhook usa service role apenas após HMAC válido.

## Permissões

- Usuário lê apenas a própria assinatura/cobranças.
- Admin comum não deve ver/alterar dados financeiros indevidos.
- Operações financeiras administrativas exigem role `financeiro` ou `super_admin`, quando aplicável.
- Alteração de role nunca deve ser feita pelo próprio usuário.

## Pagamento e acesso

- `subscriptions` no Postgres é a fonte de verdade.
- QR, dependentes e agendamento usam status local, não resposta direta da Woovi.
- `payment_pending` libera acesso com aviso.
- `blocked`, `rejected`, `expired` e sem assinatura bloqueiam acesso.

## Webhook

- Validar HMAC com corpo bruto.
- Deduplicar por `event_id`.
- Registrar payload recebido e status de processamento.
- Não confiar em valor/desconto vindo do QR ou do app.

## Checklist antes de produção

- Rodar busca por `WOOVI_APP_ID`, `WOOVI_WEBHOOK_SECRET`, `api.woovi` em `lib/`.
- Confirmar RLS de `subscriptions`, `subscription_charges` e eventos.
- Testar webhook inválido.
- Testar webhook duplicado.
- Testar bloqueio do QR para inadimplente.
- Confirmar secrets de produção antes do deploy.

