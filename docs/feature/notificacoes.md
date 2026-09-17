# Notificações

Avisos in-app e push (FCM) para divulgar novidades, especialistas e recados operacionais.

A fonte da verdade continua sendo a tabela `notifications`. O push é um canal extra: a Edge Function `send-push-campaign` lê os destinatários da campanha e envia FCM para os tokens em `device_tokens`.

## O que faz
- Admin redige uma **campanha** (título, corpo, tipo, público, destino ao toque).
- Envio imediato para um membro ou para todos (financeiro).
- RPC grava `notification_campaigns` + fan-out em `notifications`.
- Em seguida o app admin chama `send-push-campaign` (FCM). Falha de push **não** desfaz o aviso in-app.
- Membro vê o sino, a caixa de entrada e a notificação do sistema (se o aparelho registrou o token).

## Fluxo
1. Membro abre o app (staging/prod) → pede permissão → grava token em `device_tokens`.
2. Admin abre **Notificações → Campanhas → enviar**.
3. RPC `send_notification_campaign`.
4. Edge Function envia FCM HTTP v1 para cada token dos destinatários.
5. Toque no push abre o destino (`action` no payload).

## Tipos e payload
`sorteio`, `cupom`, `consulta`, `sistema`, `badge`, `divulgacao`, `profissional`.

```json
{ "action": "none" | "professional" | "professionals" | "plans" | "partners",
  "professional_id": "<uuid opcional>",
  "professional_name": "<nome opcional>" }
```

## Permissões
- Recepcionista: envio para **um** membro (10/dia). Sem broadcast.
- Financeiro: broadcast para todos (1/dia) + envio individual.

## Configuração FCM (obrigatório para o push sair)

1. Firebase Console → projeto `vita-clube-app` → **Project settings → Service accounts → Generate new private key**.
2. No projeto Supabase:

```bash
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat caminho/para/service-account.json)"
```

Ou coloque `FCM_SERVICE_ACCOUNT_JSON` no `supabase.env` (não commitar) e rode `./scripts/supabase_push_dev.sh`.

3. Aplicar migration + função:

```bash
./scripts/supabase_push_dev.sh
```

4. **Android:** `google-services.json` já está no app. No aparelho, aceitar a permissão de notificação.
5. **iOS (aparelho físico):**
   - Apple Developer → Key APNs (.p8) → Firebase → Cloud Messaging → upload da chave.
   - Xcode → Signing & Capabilities → **Push Notifications** (o arquivo `Runner.entitlements` já aponta `aps-environment=development`; para TestFlight/App Store trocar para `production`).
   - Push **não funciona no Simulator**.

Sem o secret, a campanha ainda grava a inbox; a função responde `skipped: true`.

## RLS
- `notifications`: dono lê/atualiza; admin gerencia.
- `notification_campaigns`: `is_admin()`.
- `notification_preferences`: dono lê/escreve.
- `device_tokens`: dono CRUD; admin lê.

## Fora desta fatia
- Agendamento (`send_at` + cron).
- Triggers automáticos dos templates (`trigger_event`).
