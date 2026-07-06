# Contracts: Mobile UI States

## Source of Truth

The app reads subscription status from Supabase/Postgres via the existing subscription feature. The app never infers payment approval from returning from the bank and never calls Woovi directly.

## States

### No Subscription

- **Condition**: no current subscription or `status = none`.
- **Primary CTA**: `Assinar por R$34,90/mês`.
- **Message**: Explain that VittaClube is paid, monthly and has no free trial.
- **Access**: protected features blocked.

### Explanation Before Bank

- **Condition**: user tapped subscribe.
- **Primary CTA**: `Autorizar no app do banco`.
- **Required copy**:
  - "Você autorizará uma cobrança recorrente automática de R$34,90 por mês."
  - "Não é um pagamento único."
  - "A aprovação acontece no aplicativo do seu banco."
  - "Você pode cancelar pelo aplicativo do banco."
- **Access**: not yet released.

### Waiting Authorization

- **Condition**: `status = waiting_authorization`.
- **Primary CTA**: `Abrir banco` when `paymentLinkUrl` exists; `Atualizar status` as secondary.
- **Message**: "Aguardando confirmação do seu banco."
- **Access**: blocked until confirmation and first payment.

### Active

- **Condition**: `status = active` and `payment_access_status = allowed`.
- **Display**: monthly value, current period end, next billing date.
- **Access**: allowed for titular and dependents; QR allowed.

### Payment Pending Recovery

- **Condition**: `status = payment_pending`.
- **Message**: "Não conseguimos cobrar sua mensalidade. O banco fará novas tentativas automaticamente por até 7 dias."
- **Access**: allowed with persistent warning.
- **QR**: allowed during recovery window.

### Blocked

- **Condition**: `status = blocked` or `expired` or cancelled without paid period.
- **Primary CTA**: `Restaurar minha conta`.
- **Message**: Explain unpaid monthly subscription and blocked benefits.
- **Access**: blocked for titular and dependents.
- **QR**: generation/display/validation blocked.

### Rejected

- **Condition**: `status = rejected`.
- **Primary CTA**: `Tentar novamente`.
- **Message**: "A autorização não foi concluída no banco."
- **Access**: blocked.

### Cancelled With Paid Period

- **Condition**: `status = cancelled` and `currentPeriodEnd` in future.
- **Primary CTA**: `Reativar assinatura`.
- **Message**: Access available until the paid period date; no future automatic charges.
- **Access**: allowed until period end.

## Modal: Restore Account

### Trigger

- User with blocked access attempts to open benefits, QR, appointment, dependents, profile-gated content, or partner validation.

### Required Content

- Reason: payment not regularized or subscription ended.
- Price: R$34,90/month.
- Consequence: benefits and QR are blocked until payment confirmation.
- Primary action: `Restaurar minha conta`.
- Secondary action: `Falar com suporte`.

### Accessibility

- Modal must trap focus while open.
- Title and message must be readable by screen readers.
- Primary action must be first logical action.
- Blocking cannot rely only on red color.
