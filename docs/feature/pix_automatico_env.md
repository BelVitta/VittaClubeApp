# Pix Automático Woovi - Variáveis de ambiente

Estas variáveis devem existir apenas no backend Supabase/Edge Functions. Nenhum
valor de Woovi deve ser enviado para o app Flutter.

## Sandbox

- `WOOVI_BASE_URL=https://api.woovi-sandbox.com`
- `WOOVI_APP_ID=<sandbox-app-id>`
- `WOOVI_WEBHOOK_SECRET=<sandbox-webhook-secret>`
- `WOOVI_ENVIRONMENT=sandbox`
- `VITTACLUBE_SUBSCRIPTION_VALUE_CENTS=3490`
- `VITTACLUBE_SUBSCRIPTION_INTERVAL=MONTHLY`
- `VITTACLUBE_SUBSCRIPTION_JOURNEY=PAYMENT_ON_APPROVAL`
- `VITTACLUBE_RETRY_POLICY=THREE_RETRIES_7_DAYS`

## Produção

- `WOOVI_BASE_URL=https://api.woovi.com`
- `WOOVI_APP_ID=<production-app-id>`
- `WOOVI_WEBHOOK_SECRET=<production-webhook-secret>`
- `WOOVI_ENVIRONMENT=production`

## Regras

- O app mobile nunca chama a Woovi diretamente.
- A assinatura local no Supabase é a fonte de verdade de acesso.
- Webhooks devem validar HMAC antes de processar qualquer mudança financeira.
