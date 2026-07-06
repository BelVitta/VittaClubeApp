# Quickstart: Pix Automático Woovi

## Goal

Validate subscription activation, recurring billing, recovery, cancellation and access blocking before implementation tasks are generated.

## Required Environment

Set Supabase Edge Function secrets separately for sandbox and production:

```bash
supabase secrets set WOOVI_BASE_URL=https://api.woovi-sandbox.com
supabase secrets set WOOVI_APP_ID=<sandbox-app-id>
supabase secrets set WOOVI_WEBHOOK_SECRET=<sandbox-webhook-secret>
supabase secrets set WOOVI_ENVIRONMENT=sandbox
supabase secrets set VITTACLUBE_SUBSCRIPTION_VALUE_CENTS=3490
supabase secrets set VITTACLUBE_SUBSCRIPTION_INTERVAL=MONTHLY
supabase secrets set VITTACLUBE_SUBSCRIPTION_JOURNEY=PAYMENT_ON_APPROVAL
supabase secrets set VITTACLUBE_RETRY_POLICY=THREE_RETRIES_7_DAYS
```

Production must use:

```bash
WOOVI_BASE_URL=https://api.woovi.com
WOOVI_ENVIRONMENT=production
```

## Local Checks

From Flutter app root:

```bash
flutter test
flutter analyze
```

For Edge Functions:

```bash
supabase functions serve create-woovi-subscription --env-file supabase/.env.local
supabase functions serve woovi-webhook --env-file supabase/.env.local
supabase functions serve reconcile-woovi-subscription --env-file supabase/.env.local
```

For database:

```bash
supabase db lint --local
supabase test db
```

## Sandbox Scenarios

### 1. Authorization Approved With First Payment

1. User opens paywall.
2. User sees R$34,90/month recurring explanation.
3. User opens Woovi `paymentLinkUrl`.
4. Sandbox emits approved authorization and completed first charge.
5. App shows `active`.
6. QR and dependents are accessible.

### 2. Authorization Rejected

1. Create subscription.
2. Sandbox emits rejection.
3. App shows rejected state and `Tentar novamente`.
4. Access and QR remain blocked.

### 3. Waiting Authorization

1. Create subscription.
2. Do not emit final webhook.
3. Return to app.
4. App shows "Aguardando confirmação do seu banco".
5. Access remains blocked.

### 4. Monthly Charge Completed

1. Active subscription reaches next billing cycle.
2. Sandbox emits charge created then completed.
3. Local charge becomes paid.
4. `currentPeriodEnd` advances one cycle.
5. Access remains allowed.

### 5. Charge Fails And Recovers

1. Active subscription receives first retry rejection.
2. Local status becomes `payment_pending`.
3. User receives one warning.
4. Access and QR remain allowed.
5. Later completed event arrives.
6. Local status returns to `active`.

### 6. Charge Fails And Expires

1. Active subscription receives retry rejections through the 7-day window.
2. No completed event arrives.
3. Local charge becomes expired.
4. Subscription becomes `blocked`.
5. QR, dependents and benefits show restore modal.

### 7. Cancellation

1. Active subscription receives cancellation event.
2. App shows cancelled with access until `currentPeriodEnd`.
3. After period end, app blocks access and offers reactivation.

### 8. Duplicate Webhook

1. Send the same completed event twice.
2. First event processes.
3. Second event returns success as duplicate.
4. Period is extended once and notification is not duplicated.

### 9. Reconciliation

1. Simulate missing webhook.
2. Run reconciliation for local subscription.
3. Function calls Woovi subscription status.
4. Local state updates idempotently.

## Acceptance Before Tasks

- Contracts describe all Edge Functions.
- Data model covers subscription, charge, attempt, webhook event and access history.
- UI state contract includes waiting, active, pending, blocked, rejected and cancelled.
- Sandbox scenarios cover all required business states.
- No Woovi secret is required in the Flutter app.
