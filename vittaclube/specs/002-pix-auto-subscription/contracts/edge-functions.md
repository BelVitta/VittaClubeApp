# Contracts: Supabase Edge Functions

## Environment Variables

- `WOOVI_BASE_URL`: `https://api.woovi-sandbox.com` em sandbox, `https://api.woovi.com` em produção.
- `WOOVI_APP_ID`: App ID usado no header `Authorization`.
- `WOOVI_WEBHOOK_SECRET`: segredo para validação HMAC.
- `WOOVI_ENVIRONMENT`: `sandbox` ou `production`.
- `VITTACLUBE_SUBSCRIPTION_VALUE_CENTS`: `3490`.
- `VITTACLUBE_SUBSCRIPTION_INTERVAL`: `MONTHLY`.
- `VITTACLUBE_SUBSCRIPTION_JOURNEY`: `PAYMENT_ON_APPROVAL`.
- `VITTACLUBE_RETRY_POLICY`: `THREE_RETRIES_7_DAYS`.

## Function: create-woovi-subscription

Cria contrato de Pix Automático na Woovi e persiste assinatura local em `waiting_authorization`.

### Request

```http
POST /functions/v1/create-woovi-subscription
Authorization: Bearer <user-jwt>
Content-Type: application/json
```

```json
{
  "planId": "vittaclube-monthly",
  "customer": {
    "name": "João da Silva",
    "taxID": "31324227036",
    "email": "joao@email.com",
    "phone": "5511999999999"
  }
}
```

### Woovi Request

```http
POST https://api.woovi.com/api/v1/subscriptions
Authorization: <WOOVI_APP_ID>
Content-Type: application/json
```

```json
{
  "correlationID": "vittaclube-user-<userId>-<timestamp>",
  "value": 3490,
  "interval": "MONTHLY",
  "dayGenerateCharge": 15,
  "customer": {
    "name": "João da Silva",
    "taxID": "31324227036",
    "email": "joao@email.com",
    "phone": "5511999999999"
  },
  "comment": "VittaClube - assinatura mensal recorrente R$34,90"
}
```

### Success Response

```json
{
  "subscription": {
    "id": "local-subscription-id",
    "correlationID": "vittaclube-user-42-20260602",
    "value": 3490,
    "interval": "MONTHLY",
    "status": "WAITING_AUTHORIZATION",
    "paymentLinkUrl": "https://woovi.com/subscription/auth/...",
    "createdAt": "2026-06-02T12:00:00.000Z"
  },
  "ui": {
    "state": "WAITING_AUTHORIZATION",
    "title": "Autorize no app do seu banco",
    "message": "Você está autorizando uma cobrança recorrente automática de R$34,90 por mês.",
    "primaryAction": "Abrir banco"
  }
}
```

### Error Responses

- `400`: dados do pagador incompletos ou inválidos.
- `401`: usuário não autenticado.
- `409`: já existe assinatura `active`, `payment_pending` ou `waiting_authorization`.
- `502`: Woovi indisponível ou resposta inválida.

### Required Behavior

- Não aceitar valor vindo do app; usar sempre `3490`.
- Não expor `WOOVI_APP_ID`.
- Persistir `correlationID`, `paymentLinkUrl`, `status = waiting_authorization`.
- Reutilizar assinatura `waiting_authorization` existente em vez de criar várias em cliques repetidos.

## Function: woovi-webhook

Recebe eventos Woovi, valida HMAC, deduplica e atualiza assinatura/cobrança.

### Request

```http
POST /functions/v1/woovi-webhook
Content-Type: application/json
X-Woovi-Signature: <hmac>
```

### Accepted Events

Eventos do prompt:

- `OPENPIX:SUBSCRIPTION_CREATED`
- `OPENPIX:SUBSCRIPTION_AUTHORIZED`
- `OPENPIX:SUBSCRIPTION_REJECTED`
- `OPENPIX:SUBSCRIPTION_CANCELLED`
- `OPENPIX:CHARGE_CREATED`
- `OPENPIX:CHARGE_COMPLETED`

Eventos Pix Automático oficiais equivalentes:

- `PIX_AUTOMATIC_APPROVED`
- `PIX_AUTOMATIC_REJECTED`
- `PIX_AUTOMATIC_COBR_CREATED`
- `PIX_AUTOMATIC_COBR_APPROVED`
- `PIX_AUTOMATIC_COBR_REJECTED`
- `PIX_AUTOMATIC_COBR_TRY_REJECTED`
- `PIX_AUTOMATIC_COBR_TRY_REQUESTED`
- `PIX_AUTOMATIC_COBR_COMPLETED`

### Processing Contract

```text
1. Ler corpo bruto.
2. Validar HMAC com WOOVI_WEBHOOK_SECRET.
3. Extrair eventId; se ausente, criar hash canônico do payload.
4. Inserir em woovi_webhook_events com chave única.
5. Se duplicado, retornar 200 sem novo efeito.
6. Mapear evento para transição de domínio.
7. Atualizar subscription/charge/attempt em transação.
8. Gravar subscription_access_events quando acesso mudar.
9. Retornar 200.
```

### Event Mapping

| Event | Local Effect |
|-------|--------------|
| `OPENPIX:SUBSCRIPTION_CREATED` | Confirma contrato criado; mantém `waiting_authorization` |
| `OPENPIX:SUBSCRIPTION_AUTHORIZED` / `PIX_AUTOMATIC_APPROVED` | Marca autorização aprovada; se pagamento inicial confirmado, `active` |
| `OPENPIX:SUBSCRIPTION_REJECTED` / `PIX_AUTOMATIC_REJECTED` | `rejected`, acesso bloqueado, permitir nova tentativa posterior |
| `OPENPIX:SUBSCRIPTION_CANCELLED` | `cancelled`; acesso até `current_period_end` se houver período pago |
| `OPENPIX:CHARGE_CREATED` / `PIX_AUTOMATIC_COBR_CREATED` | Cria/atualiza cobrança do ciclo |
| `PIX_AUTOMATIC_COBR_TRY_REJECTED` | Incrementa tentativa; `payment_pending`; notificação única |
| `PIX_AUTOMATIC_COBR_COMPLETED` / `OPENPIX:CHARGE_COMPLETED` | Marca cobrança paga; assinatura `active`; estende período |
| `PIX_AUTOMATIC_COBR_REJECTED` | Cobrança falhou; se janela expirada, `blocked` |

### Response

```json
{
  "ok": true,
  "deduplicated": false,
  "eventId": "woovi-event-id",
  "processedAs": "charge_completed"
}
```

## Function: reconcile-woovi-subscription

Consulta a Woovi quando webhook se perde ou suporte/rotina precisa reconciliar status.

### Request

```http
POST /functions/v1/reconcile-woovi-subscription
Authorization: Bearer <admin-or-service-jwt>
Content-Type: application/json
```

```json
{
  "subscriptionId": "local-subscription-id"
}
```

### Woovi Request

```http
GET https://api.woovi.com/api/v1/subscriptions/{idOrCorrelationID}
Authorization: <WOOVI_APP_ID>
```

### Response

```json
{
  "subscriptionId": "local-subscription-id",
  "statusBefore": "payment_pending",
  "statusAfter": "active",
  "lastReconciledAt": "2026-06-02T12:10:00.000Z"
}
```

## Function: cancel-woovi-subscription

Cancelamento por operador autorizado ou fluxo controlado.

### Request

```http
POST /functions/v1/cancel-woovi-subscription
Authorization: Bearer <admin-or-user-jwt>
Content-Type: application/json
```

```json
{
  "subscriptionId": "local-subscription-id",
  "reason": "Solicitação do cliente"
}
```

### Woovi Request

```http
DELETE https://api.woovi.com/api/v1/subscriptions/{idOrCorrelationID}
Authorization: <WOOVI_APP_ID>
```

### Required Behavior

- Se cancelamento vier do usuário, exigir que seja a própria assinatura.
- Se vier de operador, exigir role autorizada.
- Marcar `cancelled`; manter acesso até `current_period_end`.
- Gravar evento operacional.
