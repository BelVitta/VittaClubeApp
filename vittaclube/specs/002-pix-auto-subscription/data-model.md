# Data Model: Pagamentos e Assinatura Pix Automático

## Overview

O modelo amplia a base atual de `subscriptions`/`payments` para recorrência Pix Automático. `subscriptions` continua sendo a fonte de verdade do controle de acesso no app. As novas tabelas dão rastreabilidade para contrato Woovi, cobranças, tentativas, webhooks e auditoria operacional.

## Enums

### subscription_status

- `none`: usuário sem assinatura.
- `waiting_authorization`: contrato criado na Woovi, aguardando aprovação no banco.
- `active`: autorização aprovada e período pago vigente.
- `payment_pending`: primeira falha de cobrança; recuperação automática em andamento, acesso ainda liberado com aviso.
- `blocked`: cobrança expirada sem pagamento; acesso bloqueado.
- `rejected`: autorização recusada/abandonada; acesso não liberado.
- `cancelled`: recorrência cancelada; acesso depende de `current_period_end`.
- `expired`: ciclo pago encerrado após cancelamento ou bloqueio.

### charge_status

- `created`
- `scheduled`
- `paid`
- `failed`
- `retrying`
- `expired`
- `cancelled`

### charge_attempt_status

- `requested`
- `approved`
- `rejected`
- `completed`
- `failed`

### payment_access_status

- `allowed`
- `warning_pending`
- `blocked`

## Entity: Subscription

**Table**: `public.subscriptions` (evoluir tabela existente)

**Fields**:

- `id`: UUID local.
- `user_id`: titular.
- `plan_id`: plano fixo VittaClube.
- `status`: `subscription_status`.
- `payment_access_status`: status resumido para controle de acesso.
- `woovi_subscription_id`: ID/globalID retornado pela Woovi, quando houver.
- `correlation_id`: identificador único local enviado à Woovi. Único.
- `payment_link_url`: link de autorização para o banco.
- `value_cents`: inteiro, default `3490`.
- `currency`: default `BRL`.
- `interval`: default `MONTHLY`.
- `journey`: default `PAYMENT_ON_APPROVAL`.
- `retry_policy`: default `THREE_RETRIES_7_DAYS`.
- `day_generate_charge`: dia de geração/vencimento do ciclo.
- `current_period_start`: início do período pago vigente.
- `current_period_end`: fim do período pago vigente.
- `next_billing_date`: próxima cobrança esperada.
- `authorized_at`: quando o banco aprovou o consentimento.
- `cancelled_at`: quando a recorrência foi cancelada.
- `rejected_at`: quando a autorização foi recusada.
- `blocked_at`: quando acesso foi bloqueado.
- `last_reconciled_at`: última reconciliação com Woovi.
- `metadata`: JSONB para dados não decisórios.
- `created_at`, `updated_at`.

**Validation Rules**:

- Uma assinatura atual por `user_id`.
- `value_cents` deve ser `3490` nesta fase.
- `correlation_id` deve ser único e imutável depois da criação.
- `payment_link_url` só deve existir em `waiting_authorization` ou enquanto for útil para reativação.
- `payment_access_status = blocked` quando `status in (blocked, expired, rejected)` ou `cancelled` sem período pago vigente.

**State Transitions**:

```text
none -> waiting_authorization
waiting_authorization -> active
waiting_authorization -> rejected
active -> payment_pending
payment_pending -> active
payment_pending -> blocked
active -> cancelled
payment_pending -> cancelled
cancelled -> expired
blocked -> waiting_authorization
rejected -> waiting_authorization
```

## Entity: SubscriptionCharge

**Table**: `public.subscription_charges`

**Fields**:

- `id`: UUID local.
- `subscription_id`: assinatura local.
- `user_id`: titular.
- `woovi_charge_id`: ID/globalID da cobrança, quando informado.
- `woovi_cobr_id`: ID de CobR Pix Automático, quando informado.
- `correlation_id`: identificador local da cobrança.
- `subscription_correlation_id`: contrato que gerou a cobrança.
- `value_cents`: `3490`.
- `status`: `charge_status`.
- `cycle_reference`: referência do ciclo (`YYYY-MM` ou data do ciclo).
- `due_date`: data da cobrança.
- `paid_at`: confirmação de pagamento.
- `failed_at`: primeira falha.
- `recovery_started_at`: início da janela de 7 dias.
- `recovery_deadline_at`: fim da janela.
- `attempt_count`: tentativas conhecidas.
- `failure_reason`: motivo legível/suporte.
- `raw_latest_event`: JSONB do último evento aceito.
- `created_at`, `updated_at`.

**Validation Rules**:

- Cada `correlation_id` deve ser único.
- `attempt_count` não deve exceder 3 para política desta feature.
- Cobrança `paid` deve atualizar assinatura para `active`.
- Cobrança `expired` deve bloquear assinatura se não houver outro pagamento vigente.

## Entity: SubscriptionChargeAttempt

**Table**: `public.subscription_charge_attempts`

**Fields**:

- `id`: UUID local.
- `subscription_charge_id`: cobrança.
- `attempt_number`: 1 a 3.
- `status`: `charge_attempt_status`.
- `requested_at`
- `completed_at`
- `rejected_at`
- `failure_reason`
- `woovi_attempt_id`
- `raw_event`: JSONB.

**Validation Rules**:

- Único por `subscription_charge_id + attempt_number`.
- Tentativa completada não pode ser processada duas vezes.

## Entity: WooviWebhookEvent

**Table**: `public.woovi_webhook_events`

**Fields**:

- `id`: UUID local.
- `event_id`: ID único vindo da Woovi ou hash canônico do payload se ausente.
- `event_type`: nome do evento.
- `subscription_correlation_id`
- `charge_correlation_id`
- `signature_valid`: boolean.
- `processed_at`
- `processing_status`: `received`, `processed`, `ignored`, `failed`.
- `processing_error`
- `payload`: JSONB.
- `received_at`.

**Validation Rules**:

- `event_id` único.
- Evento com assinatura inválida não altera assinatura/cobrança.
- Duplicata retorna sucesso sem novo efeito.

## Entity: SubscriptionAccessEvent

**Table**: `public.subscription_access_events`

**Fields**:

- `id`
- `subscription_id`
- `user_id`
- `from_status`
- `to_status`
- `from_access_status`
- `to_access_status`
- `reason`
- `source`: `woovi_webhook`, `reconciliation`, `operator`, `system`
- `created_at`
- `metadata`

**Validation Rules**:

- Gravar em toda mudança que impacte acesso.
- Deve permitir suporte auditar bloqueio/restauração/cancelamento.

## Entity: User Payment Status

Pode ser materializado em `subscriptions.payment_access_status` e/ou view `current_user_payment_status`.

**Fields esperados pela UI**:

- `subscription_status`
- `payment_access_status`
- `can_access`
- `can_use_qr`
- `restore_required`
- `message`
- `current_period_end`
- `next_billing_date`
- `payment_link_url` quando aplicável.

## RLS

- Usuário autenticado pode ler apenas sua própria assinatura, cobranças e status resumido.
- Usuário não pode inserir/alterar diretamente assinaturas, cobranças, tentativas ou eventos.
- Edge Functions usam role de serviço para processar Woovi.
- Admin/financeiro podem consultar histórico conforme políticas existentes.
- Operador autorizado pode cancelar assinatura via função controlada, não por update direto.

## Access Rules

- `active`: titular e dependentes podem acessar; QR permitido.
- `payment_pending`: acesso e QR permanecem permitidos com aviso persistente.
- `waiting_authorization`: acesso bloqueado; tela de espera/tentar novamente.
- `rejected`: acesso bloqueado; permitir nova tentativa com explicação.
- `blocked`: acesso e QR bloqueados; modal de restauração obrigatório.
- `cancelled`: acesso permitido até `current_period_end`; depois bloqueado.
- `expired`: acesso e QR bloqueados; modal de restauração.
