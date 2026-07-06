# Contracts: Woovi Webhook Events

## Security

- A função deve validar assinatura/HMAC usando o corpo bruto.
- Payload com assinatura ausente ou inválida retorna `401` ou `400` e não altera dados de assinatura.
- Evento validado deve ser persistido em `woovi_webhook_events` antes do processamento de negócio.
- `event_id` deve ser único; duplicatas retornam `200` com `deduplicated = true`.

## Canonical Payload Fields

O handler deve normalizar campos vindos da Woovi para um formato interno:

```json
{
  "eventId": "evt_123",
  "eventType": "PIX_AUTOMATIC_COBR_COMPLETED",
  "subscriptionCorrelationID": "vittaclube-user-42-20260602",
  "chargeCorrelationID": "charge-vittaclube-user-42-20260702",
  "subscription": {
    "id": "woovi-subscription-id",
    "correlationID": "vittaclube-user-42-20260602",
    "status": "AUTHORIZED"
  },
  "charge": {
    "id": "woovi-charge-id",
    "correlationID": "charge-vittaclube-user-42-20260702",
    "value": 3490,
    "status": "COMPLETED",
    "paidAt": "2026-07-02T10:00:00.000Z"
  }
}
```

## Event Semantics

### Contract Created

Input:

- `OPENPIX:SUBSCRIPTION_CREATED`

Expected local state:

- `subscriptions.status = waiting_authorization`
- `payment_access_status = blocked`
- No QR access.

### Contract Authorized

Input:

- `OPENPIX:SUBSCRIPTION_AUTHORIZED`
- `PIX_AUTOMATIC_APPROVED`

Expected local state:

- Authorization fields updated.
- If event includes first payment confirmation or paired completed charge exists: `status = active`.
- If authorization exists but charge confirmation is pending: keep waiting/payment processing state and do not release until paid.

### Contract Rejected

Input:

- `OPENPIX:SUBSCRIPTION_REJECTED`
- `PIX_AUTOMATIC_REJECTED`

Expected local state:

- `status = rejected`
- `payment_access_status = blocked`
- Do not recreate automatically.
- UI can show "Tentar novamente".

### Contract Cancelled

Input:

- `OPENPIX:SUBSCRIPTION_CANCELLED`

Expected local state:

- `status = cancelled`
- If `current_period_end` is in future: access allowed until that date.
- After period end: access blocked/expired.

### Charge Created

Input:

- `OPENPIX:CHARGE_CREATED`
- `PIX_AUTOMATIC_COBR_CREATED`

Expected local state:

- Upsert `subscription_charges`.
- No access change by itself.

### Charge Try Requested

Input:

- `PIX_AUTOMATIC_COBR_TRY_REQUESTED`

Expected local state:

- Upsert attempt as `requested`.
- Keep existing access state.

### Charge Try Rejected

Input:

- `PIX_AUTOMATIC_COBR_TRY_REJECTED`

Expected local state:

- Upsert attempt as `rejected`.
- If first failure: `subscription.status = payment_pending`.
- `payment_access_status = warning_pending`.
- Notify once per charge.

### Charge Completed

Input:

- `OPENPIX:CHARGE_COMPLETED`
- `PIX_AUTOMATIC_COBR_COMPLETED`

Expected local state:

- `subscription_charges.status = paid`.
- `subscriptions.status = active`.
- `payment_access_status = allowed`.
- Extend `current_period_start` and `current_period_end` by one cycle.
- Clear pending warning.

### Charge Rejected/Expired

Input:

- `PIX_AUTOMATIC_COBR_REJECTED`
- `OPENPIX:CHARGE_EXPIRED` if received for equivalent cycle.

Expected local state:

- If within recovery window: `payment_pending`.
- If beyond 7 days or attempts exhausted: `blocked`.
- QR and dependent access blocked when `blocked`.

## Idempotency Examples

- Receiving `PIX_AUTOMATIC_COBR_COMPLETED` twice for same event ID must not extend the subscription twice.
- Receiving `PIX_AUTOMATIC_COBR_TRY_REJECTED` twice must not send two notifications.
- Receiving `OPENPIX:SUBSCRIPTION_CANCELLED` after local cancellation must preserve the same cancelled state.

## Out-of-Order Handling

- Completed charge wins over earlier retry rejection for the same charge.
- Contract rejection after active payment must be flagged for reconciliation, not blindly block a paid active period.
- Cancellation affects future recurrence but must not remove already paid access before `current_period_end`.
