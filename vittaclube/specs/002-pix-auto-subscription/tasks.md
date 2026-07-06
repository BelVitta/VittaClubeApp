# Tasks: Pagamentos e Assinatura Pix Automático

**Input**: Design documents from `/specs/002-pix-auto-subscription/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: MANDATORY. This task list follows TDD: write the automated tests for each behavior before implementing the corresponding production code.

**Architecture Source of Truth**:

- Flutter app reads subscription/payment status from Supabase/Postgres only.
- Woovi integration is backend-only through Supabase Edge Functions.
- `subscriptions` in Postgres is the source of truth for access.
- No Woovi secret, App ID, webhook secret, or HMAC logic may exist in Flutter.
- QR, benefits, appointments, and dependents must be gated by subscription access status.
- During `payment_pending`, access remains allowed with persistent warning.
- After recovery expires or subscription is rejected/blocked/expired, access and QR are blocked.

**Implementation notes (2026-06-02)**:

- Existing `lib/features/subscription` already follows feature-based Clean Architecture with `domain`, `data`, and `presentation`; Pix Automático was added inside those boundaries.
- Existing `core/payment` remains legacy/future-only for non-Pix providers. The Woovi Pix Automático integration is backend-only through Supabase Edge Functions.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on incomplete tasks)
- **[Story]**: Which user story this task belongs to
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare folders, ignore rules, and test surfaces for the Pix Automático implementation.

- [X] T001 Verify existing subscription feature boundaries and record implementation notes in `specs/002-pix-auto-subscription/tasks.md`
- [X] T002 Verify existing payment gateway boundary and record whether it remains legacy/future-only in `specs/002-pix-auto-subscription/tasks.md`
- [X] T003 Create Edge Function folder `../supabase/functions/create-woovi-subscription/index.ts`
- [X] T004 Create Edge Function folder `../supabase/functions/woovi-webhook/index.ts`
- [X] T005 Create Edge Function folder `../supabase/functions/reconcile-woovi-subscription/index.ts`
- [X] T006 Create Edge Function folder `../supabase/functions/cancel-woovi-subscription/index.ts`
- [X] T007 [P] Create shared Edge Function payment utilities folder `../supabase/functions/_shared/woovi/`
- [X] T008 [P] Create Flutter subscription test folders in `../test/features/subscription/`
- [X] T009 [P] Create Supabase Edge Function test folder `../supabase/functions/tests/`
- [X] T010 [P] Create Supabase DB test folder `../supabase/tests/`
- [X] T011 Verify `.env`, `.env.local`, and Supabase secrets files are ignored in `../.gitignore`
- [X] T012 [P] Add local secret documentation scaffold in `../docs/feature/pix_automatico_env.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Define shared schema, status model, Edge Function utilities, and contracts that block all user stories.

**CRITICAL**: No user story implementation can begin until this phase is complete.

### Foundational Tests (MANDATORY)

- [X] T013 [P] Create unit tests for subscription status access matrix in `../test/features/subscription/domain/subscription_access_policy_test.dart`
- [X] T014 [P] Create unit tests for billing cycle day calculation including day 31/month-end in `../test/features/subscription/domain/billing_cycle_policy_test.dart`
- [X] T015 [P] Create unit tests for Woovi event normalization in `../supabase/functions/tests/woovi_event_mapper_test.ts`
- [X] T016 [P] Create unit tests for Woovi HMAC validation in `../supabase/functions/tests/woovi_hmac_test.ts`
- [X] T017 [P] Create unit tests for canonical event ID/hash fallback in `../supabase/functions/tests/woovi_event_id_test.ts`
- [X] T018 [P] Create DB tests for RLS own-subscription read and cross-user denial in `../supabase/tests/subscription_rls_and_webhooks.sql`

### Foundational Implementation

- [X] T019 Create Pix Automático migration with enums and extended `subscriptions` fields in `../supabase/migrations/20260602_pix_automatic_subscription.sql`
- [X] T020 Add `subscription_charges`, `subscription_charge_attempts`, `woovi_webhook_events`, and `subscription_access_events` schema in `../supabase/migrations/20260602_pix_automatic_subscription.sql`
- [X] T021 Add unique indexes for `subscriptions.correlation_id`, `subscription_charges.correlation_id`, and `woovi_webhook_events.event_id` in `../supabase/migrations/20260602_pix_automatic_subscription.sql`
- [X] T022 Add constraints for fixed `value_cents = 3490`, one current subscription per user, and max 3 attempts in `../supabase/migrations/20260602_pix_automatic_subscription.sql`
- [X] T023 Add RLS policies for own subscription/charges read and no direct user writes in `../supabase/migrations/20260602_pix_automatic_subscription.sql`
- [X] T024 Add admin/financeiro/service-role access policies for subscription operations in `../supabase/migrations/20260602_pix_automatic_subscription.sql`
- [X] T025 Add `current_user_payment_status` view or RPC for mobile access checks in `../supabase/migrations/20260602_pix_automatic_subscription.sql`
- [X] T026 Add access audit helper functions for block/allow transitions in `../supabase/migrations/20260602_pix_automatic_subscription.sql`
- [X] T027 [P] Create Flutter subscription status enums in `../lib/features/subscription/domain/entities/subscription_status.dart`
- [X] T028 [P] Create Flutter subscription access policy helper in `../lib/features/subscription/domain/services/subscription_access_policy.dart`
- [X] T029 [P] Create billing cycle policy helper in `../lib/features/subscription/domain/services/billing_cycle_policy.dart`
- [X] T030 Update `SubscriptionEntity` with Pix Automático fields in `../lib/features/subscription/domain/entities/subscription_entity.dart`
- [X] T031 Update `SubscriptionModel` JSON mapping for Pix Automático fields in `../lib/features/subscription/data/models/subscription_model.dart`
- [X] T032 [P] Create shared Woovi env utility in `../supabase/functions/_shared/woovi/env.ts`
- [X] T033 [P] Create shared Woovi HTTP client in `../supabase/functions/_shared/woovi/client.ts`
- [X] T034 [P] Create shared Woovi HMAC verifier in `../supabase/functions/_shared/woovi/hmac.ts`
- [X] T035 [P] Create shared Woovi event mapper in `../supabase/functions/_shared/woovi/event_mapper.ts`
- [X] T036 [P] Create shared Edge Function response helpers in `../supabase/functions/_shared/http.ts`
- [X] T037 Update dependency injection registrations for new subscription use cases placeholders in `../lib/core/di/injection_container.dart`

**Checkpoint**: Database contract, status model, and Woovi utility boundaries exist and are testable.

---

## Phase 3: User Story 1 - Ativar assinatura recorrente (Priority: P1) MVP

**Goal**: User understands R$34,90/month recurring Pix Automático, authorizes in bank, and app shows real waiting/active/rejected status.

**Independent Test**: Create subscription in sandbox, receive approved first payment, and verify access changes from waiting to active without mobile calling Woovi.

### Tests for User Story 1 (MANDATORY)

- [ ] T038 [P] [US1] Create Edge Function contract test for successful subscription creation in `../supabase/functions/tests/create_woovi_subscription_test.ts`
- [ ] T039 [P] [US1] Create Edge Function contract test for duplicate waiting authorization reuse in `../supabase/functions/tests/create_woovi_subscription_idempotency_test.ts`
- [ ] T040 [P] [US1] Create Edge Function contract test for rejecting missing customer fields in `../supabase/functions/tests/create_woovi_subscription_validation_test.ts`
- [ ] T041 [P] [US1] Create Flutter datasource test for invoking only Supabase function, not Woovi, in `../test/features/subscription/data/subscription_supabase_datasource_pix_test.dart`
- [X] T042 [P] [US1] Create Flutter use case test for create Pix Automático subscription in `../test/features/subscription/domain/create_pix_automatic_subscription_usecase_test.dart`
- [X] T043 [P] [US1] Create widget test for explanation-before-bank screen copy and CTA in `../test/features/subscription/presentation/pix_automatic_explanation_page_test.dart`
- [X] T044 [P] [US1] Create widget test for waiting authorization state in `../test/features/subscription/presentation/subscription_status_states_test.dart`
- [X] T045 [P] [US1] Create widget test for authorization rejected state in `../test/features/subscription/presentation/subscription_rejected_state_test.dart`

### Implementation for User Story 1

- [X] T046 [US1] Implement `create-woovi-subscription` request validation and auth guard in `../supabase/functions/create-woovi-subscription/index.ts`
- [X] T047 [US1] Implement Woovi `POST /api/v1/subscriptions` call with `value=3490`, `interval=MONTHLY`, and generated `correlationID` in `../supabase/functions/create-woovi-subscription/index.ts`
- [X] T048 [US1] Persist or reuse local `waiting_authorization` subscription with `paymentLinkUrl` in `../supabase/functions/create-woovi-subscription/index.ts`
- [X] T049 [US1] Add `createPixAutomaticSubscription` to repository contract in `../lib/features/subscription/domain/repositories/subscription_repository.dart`
- [X] T050 [US1] Implement create Pix Automático datasource call to Supabase function in `../lib/features/subscription/data/datasources/subscription_supabase_datasource.dart`
- [X] T051 [US1] Implement repository mapping for create Pix Automático in `../lib/features/subscription/data/repositories/subscription_repository_impl.dart`
- [X] T052 [US1] Create `CreatePixAutomaticSubscriptionUseCase` in `../lib/features/subscription/domain/usecases/create_pix_automatic_subscription_usecase.dart`
- [X] T053 [US1] Update `SubscriptionBloc` events and states for creating/waiting/rejected status in `../lib/features/subscription/presentation/bloc/subscription_bloc.dart`
- [X] T054 [US1] Create explanation screen before bank redirect in `../lib/features/subscription/presentation/pages/pix_automatic_explanation_page.dart`
- [X] T055 [US1] Create status page widgets for no subscription, waiting authorization, active, and rejected in `../lib/features/subscription/presentation/widgets/subscription_status_cards.dart`
- [X] T056 [US1] Integrate `url_launcher` opening of `paymentLinkUrl` only after explanation confirmation in `../lib/features/subscription/presentation/pages/pix_automatic_explanation_page.dart`
- [X] T057 [US1] Wire subscribe CTA from plan/payment flow to Pix Automático explanation in `../lib/features/plans/presentation/pages/payment_page.dart`
- [X] T058 [US1] Register create subscription use case and BLoC dependencies in `../lib/core/di/injection_container.dart`

**Checkpoint**: User can start Pix Automático authorization and see waiting/rejected/active states from local status.

---

## Phase 4: User Story 2 - Cobrar mensalidade recorrente automaticamente (Priority: P1)

**Goal**: Recurring monthly charge events update charges and extend paid period without user action.

**Independent Test**: Simulate charge created and completed webhook for an active subscription and verify `current_period_end` advances once.

### Tests for User Story 2 (MANDATORY)

- [ ] T059 [P] [US2] Create webhook test for `OPENPIX:CHARGE_CREATED` / `PIX_AUTOMATIC_COBR_CREATED` upsert in `../supabase/functions/tests/woovi_webhook_charge_created_test.ts`
- [ ] T060 [P] [US2] Create webhook test for `OPENPIX:CHARGE_COMPLETED` / `PIX_AUTOMATIC_COBR_COMPLETED` period extension in `../supabase/functions/tests/woovi_webhook_charge_completed_test.ts`
- [ ] T061 [P] [US2] Create webhook duplicate completed-charge test proving period extends once in `../supabase/functions/tests/woovi_webhook_duplicate_completed_test.ts`
- [ ] T062 [P] [US2] Create DB test for charge unique correlation and paid status transitions in `../supabase/tests/subscription_charges.sql`
- [X] T063 [P] [US2] Create Flutter widget test for active status showing value and next billing date in `../test/features/subscription/presentation/subscription_active_state_test.dart`

### Implementation for User Story 2

- [X] T064 [US2] Implement raw-body HMAC validation and event persistence shell in `../supabase/functions/woovi-webhook/index.ts`
- [X] T065 [US2] Implement charge created event mapping and upsert in `../supabase/functions/woovi-webhook/index.ts`
- [X] T066 [US2] Implement charge completed event mapping, paid charge update, and one-cycle period extension in `../supabase/functions/woovi-webhook/index.ts`
- [X] T067 [US2] Implement duplicate-event short-circuit returning 200 without side effects in `../supabase/functions/woovi-webhook/index.ts`
- [X] T068 [US2] Persist access audit event when charge completed changes access to allowed in `../supabase/functions/woovi-webhook/index.ts`
- [X] T069 [US2] Update Flutter active status UI to display R$34,90, period end, and next billing date in `../lib/features/subscription/presentation/widgets/subscription_status_cards.dart`

**Checkpoint**: Monthly paid webhook keeps subscription active and updates charge/history exactly once.

---

## Phase 5: User Story 3 - Recuperar cobrança com falha (Priority: P1)

**Goal**: First payment failure marks pending with warning, retries can recover, and expiration blocks access after 7 days or attempts exhausted.

**Independent Test**: Simulate try rejected, completed recovery, and expired charge scenarios independently.

### Tests for User Story 3 (MANDATORY)

- [ ] T070 [P] [US3] Create webhook test for first `PIX_AUTOMATIC_COBR_TRY_REJECTED` marking `payment_pending` in `../supabase/functions/tests/woovi_webhook_try_rejected_test.ts`
- [ ] T071 [P] [US3] Create webhook test proving duplicate failure does not duplicate notification/access event in `../supabase/functions/tests/woovi_webhook_duplicate_failure_test.ts`
- [ ] T072 [P] [US3] Create webhook test for recovered charge returning subscription to active in `../supabase/functions/tests/woovi_webhook_recovered_charge_test.ts`
- [ ] T073 [P] [US3] Create webhook test for expired/rejected charge blocking access after recovery window in `../supabase/functions/tests/woovi_webhook_charge_expired_test.ts`
- [X] T074 [P] [US3] Create unit test for access allowed during `payment_pending` in `../test/features/subscription/domain/subscription_payment_pending_access_test.dart`
- [X] T075 [P] [US3] Create widget test for persistent payment pending warning in `../test/features/subscription/presentation/subscription_payment_pending_state_test.dart`
- [X] T076 [P] [US3] Create widget test for blocked state after recovery expiration in `../test/features/subscription/presentation/subscription_blocked_state_test.dart`

### Implementation for User Story 3

- [X] T077 [US3] Implement `PIX_AUTOMATIC_COBR_TRY_REJECTED` attempt upsert and first-failure pending transition in `../supabase/functions/woovi-webhook/index.ts`
- [X] T078 [US3] Implement one-notification marker or access event guard for failed charge in `../supabase/functions/woovi-webhook/index.ts`
- [X] T079 [US3] Implement recovered charge transition from `payment_pending` to `active` in `../supabase/functions/woovi-webhook/index.ts`
- [X] T080 [US3] Implement `PIX_AUTOMATIC_COBR_REJECTED` / `OPENPIX:CHARGE_EXPIRED` blocking rules in `../supabase/functions/woovi-webhook/index.ts`
- [X] T081 [US3] Update access policy helper for `payment_pending`, `blocked`, and `expired` in `../lib/features/subscription/domain/services/subscription_access_policy.dart`
- [X] T082 [US3] Add payment pending warning widget in `../lib/features/subscription/presentation/widgets/subscription_status_cards.dart`
- [X] T083 [US3] Add blocked status card with restore CTA in `../lib/features/subscription/presentation/widgets/subscription_status_cards.dart`

**Checkpoint**: Failed payment recovery window behaves exactly as specified and blocks after expiration.

---

## Phase 6: User Story 4 - Bloquear acesso e QR quando inadimplente (Priority: P1)

**Goal**: Block QR, benefits, appointments, and dependents for blocked/rejected/expired subscriptions and show restore modal.

**Independent Test**: Put subscription in blocked state and try QR/benefit/dependent flows; every flow shows restore modal and no QR can be used.

### Tests for User Story 4 (MANDATORY)

- [X] T084 [P] [US4] Create unit test for `canUseQr=false` in blocked/rejected/expired states in `../test/features/subscription/domain/can_use_qr_policy_test.dart`
- [X] T085 [P] [US4] Create widget test for restore account modal content and CTA in `../test/features/subscription/presentation/restore_account_modal_test.dart`
- [X] T086 [P] [US4] Create widget test for QR blocked when subscription is blocked in `../test/features/card/qr_subscription_gate_test.dart`
- [X] T087 [P] [US4] Create widget test for dependents access blocked when holder is blocked in `../test/features/dependents/dependents_subscription_gate_test.dart`
- [X] T088 [P] [US4] Create widget test for appointment/benefit access blocked by subscription in `../test/features/consultation/consultation_subscription_gate_test.dart`

### Implementation for User Story 4

- [X] T089 [US4] Create reusable subscription gate widget in `../lib/features/subscription/presentation/widgets/subscription_access_gate.dart`
- [X] T090 [US4] Create restore account modal in `../lib/features/subscription/presentation/widgets/restore_account_modal.dart`
- [X] T091 [US4] Create `CanUseQrUseCase` in `../lib/features/subscription/domain/usecases/can_use_qr_usecase.dart`
- [X] T092 [US4] Create `CanAccessBenefitsUseCase` in `../lib/features/subscription/domain/usecases/can_access_benefits_usecase.dart`
- [X] T093 [US4] Integrate subscription QR gate in `../lib/features/card/presentation/widgets/qr_code_sheet.dart`
- [X] T094 [US4] Integrate subscription gate in dependents entry/list page in `../lib/features/dependents/presentation/pages/dependents_page.dart`
- [X] T095 [US4] Integrate subscription gate in consultation scheduling flow in `../lib/features/consultation/presentation/pages/consultation_schedule_page.dart`
- [X] T096 [US4] Register access use cases in DI in `../lib/core/di/injection_container.dart`

**Checkpoint**: Blocked users cannot use QR or protected club features and always see restoration path.

---

## Phase 7: User Story 5 - Refletir cancelamento da recorrência (Priority: P2)

**Goal**: Bank or operator cancellation updates local status, preserves paid period, and blocks after period end.

**Independent Test**: Simulate cancellation webhook and operator cancellation, then verify paid-period access and post-period block.

### Tests for User Story 5 (MANDATORY)

- [ ] T097 [P] [US5] Create webhook test for `OPENPIX:SUBSCRIPTION_CANCELLED` preserving paid period access in `../supabase/functions/tests/woovi_webhook_subscription_cancelled_test.ts`
- [ ] T098 [P] [US5] Create Edge Function contract test for operator cancellation in `../supabase/functions/tests/cancel_woovi_subscription_test.ts`
- [X] T099 [P] [US5] Create Flutter use case test for cancel subscription in `../test/features/subscription/domain/cancel_subscription_usecase_test.dart`
- [X] T100 [P] [US5] Create widget test for cancelled-with-paid-period state in `../test/features/subscription/presentation/subscription_cancelled_state_test.dart`
- [ ] T101 [P] [US5] Create admin widget test for viewing/cancelling user subscription in `../test/features/admin/presentation/admin_subscription_detail_test.dart`

### Implementation for User Story 5

- [X] T102 [US5] Implement subscription cancelled webhook mapping in `../supabase/functions/woovi-webhook/index.ts`
- [X] T103 [US5] Implement `cancel-woovi-subscription` auth/role validation in `../supabase/functions/cancel-woovi-subscription/index.ts`
- [X] T104 [US5] Implement Woovi `DELETE /api/v1/subscriptions/{id}` call and local cancellation audit in `../supabase/functions/cancel-woovi-subscription/index.ts`
- [X] T105 [US5] Add `cancelSubscription` to repository contract in `../lib/features/subscription/domain/repositories/subscription_repository.dart`
- [X] T106 [US5] Implement cancel subscription datasource/repository mapping in `../lib/features/subscription/data/datasources/subscription_supabase_datasource.dart`
- [X] T107 [US5] Create `CancelSubscriptionUseCase` in `../lib/features/subscription/domain/usecases/cancel_subscription_usecase.dart`
- [X] T108 [US5] Add cancelled-with-paid-period UI state in `../lib/features/subscription/presentation/widgets/subscription_status_cards.dart`
- [ ] T109 [US5] Create admin subscription detail page in `../lib/features/admin/presentation/pages/subscriptions/admin_subscription_detail_page.dart`
- [ ] T110 [US5] Add admin subscription history widgets in `../lib/features/admin/presentation/widgets/admin_subscription_history.dart`
- [X] T111 [US5] Register cancel/admin dependencies in `../lib/core/di/injection_container.dart`

**Checkpoint**: Cancellation is visible, auditable, and access remains only for paid period.

---

## Phase 8: User Story 6 - Validar cenários em sandbox (Priority: P2)

**Goal**: QA can exercise all required sandbox scenarios without real bank account or production secrets.

**Independent Test**: Run sandbox scenario scripts/tests from quickstart and verify local statuses.

### Tests for User Story 6 (MANDATORY)

- [ ] T112 [P] [US6] Create sandbox test for approved authorization with first payment in `../supabase/functions/tests/sandbox_authorization_approved_test.ts`
- [ ] T113 [P] [US6] Create sandbox test for authorization rejected in `../supabase/functions/tests/sandbox_authorization_rejected_test.ts`
- [ ] T114 [P] [US6] Create sandbox test for waiting authorization with no final webhook in `../supabase/functions/tests/sandbox_waiting_authorization_test.ts`
- [ ] T115 [P] [US6] Create sandbox test for monthly charge completed in `../supabase/functions/tests/sandbox_monthly_charge_completed_test.ts`
- [ ] T116 [P] [US6] Create sandbox test for charge failure recovered in `../supabase/functions/tests/sandbox_charge_recovered_test.ts`
- [ ] T117 [P] [US6] Create sandbox test for charge failure expired in `../supabase/functions/tests/sandbox_charge_expired_test.ts`
- [ ] T118 [P] [US6] Create sandbox test for duplicate webhook in `../supabase/functions/tests/sandbox_duplicate_webhook_test.ts`
- [ ] T119 [P] [US6] Create sandbox test for environment switch sandbox/production base URL in `../supabase/functions/tests/woovi_env_test.ts`

### Implementation for User Story 6

- [ ] T120 [US6] Implement Woovi mock fixtures for sandbox event scenarios in `../supabase/functions/tests/fixtures/woovi_events.ts`
- [X] T121 [US6] Implement `reconcile-woovi-subscription` auth/role validation in `../supabase/functions/reconcile-woovi-subscription/index.ts`
- [X] T122 [US6] Implement Woovi `GET /api/v1/subscriptions/{id}` reconciliation call in `../supabase/functions/reconcile-woovi-subscription/index.ts`
- [X] T123 [US6] Implement idempotent local reconciliation mapping and `last_reconciled_at` update in `../supabase/functions/reconcile-woovi-subscription/index.ts`
- [X] T124 [US6] Add `refreshSubscriptionStatus` to repository contract in `../lib/features/subscription/domain/repositories/subscription_repository.dart`
- [X] T125 [US6] Implement refresh status datasource/repository mapping in `../lib/features/subscription/data/datasources/subscription_supabase_datasource.dart`
- [X] T126 [US6] Create `RefreshSubscriptionStatusUseCase` in `../lib/features/subscription/domain/usecases/refresh_subscription_status_usecase.dart`
- [X] T127 [US6] Add UI refresh action for waiting/pending states in `../lib/features/subscription/presentation/bloc/subscription_bloc.dart`

**Checkpoint**: All quickstart sandbox scenarios are represented by tests and reconciliation path exists.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, security, LGPD, validation, and final quality gates.

- [X] T128 [P] Update Woovi environment variables documentation in `../docs/feature/pix_automatico_env.md`
- [X] T129 [P] Document Pix Automático status/state flow in `../docs/feature/pix_automatico_fluxo.md`
- [X] T130 [P] Document webhook events and idempotency policy in `../docs/feature/pix_automatico_webhooks.md`
- [X] T131 [P] Add security checklist for secrets, HMAC, service role, RLS, and no Woovi mobile calls in `../docs/feature/pix_automatico_security.md`
- [X] T132 [P] Add LGPD checklist for CPF/taxID, phone, payment status visibility, support history, and retention in `../docs/feature/pix_automatico_lgpd.md`
- [X] T133 [P] Add manual mobile accessibility checklist for subscription screens in `../docs/feature/pix_automatico_accessibility.md`
- [X] T134 Validate no `WOOVI_APP_ID`, `WOOVI_WEBHOOK_SECRET`, or Woovi base URL appears in Flutter code by scanning `../lib/`
- [X] T135 Run `dart format` for changed Flutter files from `../`
- [ ] T136 Run Deno formatting/checks for Supabase functions in `../supabase/functions/`
- [X] T137 Run `flutter test` from `../`
- [X] T138 Run `flutter analyze` from `../`
- [ ] T139 Run Supabase DB lint/tests for migrations and RLS in `../supabase/`
- [ ] T140 Run Edge Function tests for Woovi flows in `../supabase/functions/tests/`
- [ ] T141 Execute quickstart sandbox scenarios from `specs/002-pix-auto-subscription/quickstart.md`
- [ ] T142 Verify all P1 stories are independently demonstrable and update `specs/002-pix-auto-subscription/tasks.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup and blocks all user stories.
- **US1 Activation (Phase 3)**: Depends on Foundational; MVP.
- **US2 Recurring Paid Charge (Phase 4)**: Depends on Foundational and can run after webhook shell exists; safest after US1.
- **US3 Failed Charge Recovery (Phase 5)**: Depends on US2 charge/webhook model.
- **US4 Access/QR Blocking (Phase 6)**: Depends on Foundational status model; should validate after US3 blocked states exist.
- **US5 Cancellation (Phase 7)**: Depends on Foundational and US2 period model.
- **US6 Sandbox/Reconciliation (Phase 8)**: Depends on Edge Function contracts from US1-US5.
- **Polish (Phase 9)**: Depends on all desired user stories.

### User Story Dependencies

- **US1**: Independent MVP for paid subscription activation and waiting/rejected states.
- **US2**: Requires subscription and webhook foundation; extends recurring paid cycles.
- **US3**: Requires charge model from US2; handles recovery and blocking.
- **US4**: Uses subscription access policy; integrates with QR/dependents/appointments.
- **US5**: Uses subscription period model; handles cancellation and admin operator surface.
- **US6**: Cross-story validation of sandbox and reconciliation.

### Within Each User Story

- Tests MUST be written and fail before implementation.
- Domain/access policy before presentation gates.
- Migration and RLS before Edge Functions rely on tables.
- Edge Function webhook security/deduplication before event side effects.
- Datasource/repository before BLoC/UI.
- UI content must be specific, financial, and free of placeholders.

## Parallel Opportunities

- Setup folders T007-T010 can run in parallel.
- Foundational tests T013-T018 can run in parallel.
- Foundational utilities T027-T036 can run in parallel after migration shape is agreed.
- US1 tests T038-T045 can run in parallel.
- US2 tests T059-T063 can run in parallel.
- US3 tests T070-T076 can run in parallel.
- US4 tests T084-T088 can run in parallel.
- US5 tests T097-T101 can run in parallel.
- US6 tests T112-T119 can run in parallel.
- Documentation tasks T128-T133 can run in parallel.

## Parallel Example: User Story 1

```bash
Task: "T038 Edge Function contract test for successful subscription creation"
Task: "T042 Flutter use case test for create Pix Automático subscription"
Task: "T043 Widget test for explanation-before-bank screen"
Task: "T044 Widget test for waiting authorization state"
```

## Parallel Example: User Story 4

```bash
Task: "T084 Unit test for canUseQr=false in blocked/rejected/expired states"
Task: "T085 Widget test for restore account modal"
Task: "T086 Widget test for QR blocked when subscription is blocked"
Task: "T087 Widget test for dependents access blocked"
```

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete US1 activation flow end to end.
3. Validate that the app never calls Woovi directly and that waiting/rejected/active states are sourced from Supabase.
4. Stop and demonstrate subscription creation with sandbox/mock Woovi response.

### Incremental Delivery

1. US1: Activation and payment link.
2. US2: Recurring paid charge.
3. US3: Failed payment recovery and blocked state.
4. US4: QR/benefits/dependents access gates.
5. US5: Cancellation and admin operator support.
6. US6: Sandbox and reconciliation hardening.

### Final Quality Gates

- All tests for status, access, QR block, webhook HMAC, duplicate event, RLS, and sandbox scenarios pass.
- No Woovi secrets exist in Flutter code.
- `flutter test` passes.
- `flutter analyze` is executed and new issues are resolved or explicitly documented if pre-existing.
- Supabase migrations are linted/tested locally or in staging.
- Quickstart sandbox scenarios are demonstrable.
