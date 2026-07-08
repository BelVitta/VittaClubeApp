# Tasks: Dependentes e Validacao de QR

**Input**: Design documents from `/specs/001-loyalty-card-app/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: MANDATORY. This task list follows TDD: tests in each user-story phase
must be written and must fail before implementation tasks for that phase.

**Business Rules Source of Truth**:

- **RN-01**: Cada titular pode ter no maximo `max_dependents_per_holder` dependentes ativos. Default: 2. Parametro global configuravel, nunca hardcoded.
- **RN-02**: Cada dependente tem `monthly_uses_per_dependent` usos por ciclo. Default: 2. Parametro global configuravel.
- **RN-03**: Os 2 primeiros dependentes sao gratuitos. Nao ha cobranca de add-on neste momento.
- **RN-04**: O debito de cota ocorre somente na validacao do QR pela recepcao. Agendamento nunca debita cota.
- **RN-05**: Usos restantes = `monthly_uses_per_dependent` menos usos em estado utilizado no ciclo corrente. Agendamentos nao validados nao contam.
- **RN-06**: O ciclo de reset e pela data de adesao do titular, nao por mes-calendario.
- **RN-07**: Transicao `agendado -> utilizado` deve ser atomica, idempotente e protegida contra concorrencia.
- **RN-08**: QR carrega apenas identificador opaco e assinado do agendamento. Validacao real sempre no servidor.
- **RN-09**: CPF do dependente e unico globalmente entre dependentes ativos.
- **RN-10**: Uso so e liberado se titular estiver com assinatura em dia e dependente estiver ativo.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare the dependents feature structure, settings keys, and test organization.

- [X] T001 Create/switch git branch `feature/dependentes` from repository root `../`
- [X] T002 Create dependents feature folders in `../lib/features/dependents/`
- [X] T003 [P] Create dependents test folders in `../test/features/dependents/`
- [X] T004 [P] Add `max_dependents_per_holder` and `monthly_uses_per_dependent` seed/default rows in `../supabase/migrations/20260601_dependents_settings.sql`
- [X] T005 [P] Add typed setting keys for dependents in `../lib/core/services/clinic_settings_service.dart`
- [X] T006 [P] Add dependents test helpers and mock data builders in `../test/features/dependents/dependents_test_helpers.dart`
- [X] T007 [P] Document the rules RN-01 to RN-10 in `../docs/feature/dependentes.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Define shared schema, entities, repositories, and service contracts needed before user stories.

**CRITICAL**: No user story implementation can begin until this phase is complete.

- [X] T008 Create Supabase migration for `dependents`, dependent-aware `appointments`, `usage_records`, indexes, status enums, and CPF uniqueness among active dependents in `../supabase/migrations/20260601_dependents_schema.sql`
- [X] T009 [P] Create `DependentEntity` in `../lib/features/dependents/domain/entities/dependent_entity.dart`
- [X] T010 [P] Create `DependentAppointmentEntity` in `../lib/features/dependents/domain/entities/dependent_appointment_entity.dart`
- [X] T011 [P] Create `UsageRecordEntity` in `../lib/features/dependents/domain/entities/usage_record_entity.dart`
- [X] T012 [P] Create dependents enums for beneficiary type, dependent status, appointment status, and validation result in `../lib/features/dependents/domain/entities/dependent_enums.dart`
- [X] T013 [P] Create `DependentsRepository` contract in `../lib/features/dependents/domain/repositories/dependents_repository.dart`
- [X] T014 [P] Create `DependentAppointmentRepository` contract in `../lib/features/dependents/domain/repositories/dependent_appointment_repository.dart`
- [X] T015 [P] Create `QrValidationRepository` contract in `../lib/features/dependents/domain/repositories/qr_validation_repository.dart`
- [X] T016 [P] Create data models for Dependent, DependentAppointment, and UsageRecord in `../lib/features/dependents/data/models/dependent_models.dart`
- [X] T017 [P] Create datasource interfaces in `../lib/features/dependents/data/datasources/dependents_datasource.dart`
- [X] T018 Create repository implementations returning `Either<Failure, Entity>` in `../lib/features/dependents/data/repositories/dependents_repository_impl.dart`
- [X] T019 Register dependents datasource, repositories, use cases, and BLoCs placeholders in `../lib/core/di/injection_container.dart`

**Checkpoint**: Schema and domain/data contracts exist; TDD phases can now start.

---

## Phase 3: User Story 1 - Gerenciar dependentes do titular (Priority: P1)

**Goal**: Cliente consegue cadastrar, listar e inativar dependentes respeitando limite configuravel e CPF unico.

**Independent Test**: With settings defaulting to 2 dependents and 2 uses, a holder can create 2 active dependents, cannot create a 3rd active dependent, cannot reuse an active dependent CPF under another holder, and can list dependents with remaining uses.

### Tests for User Story 1 (MANDATORY)

> Write these tests first and confirm they fail before implementation.

- [X] T020 [P] [US1] Contract test for create dependent repository/use case in `../test/features/dependents/contracts/create_dependent_contract_test.dart`
- [X] T021 [P] [US1] Contract test for list dependents with remaining quota in `../test/features/dependents/contracts/list_dependents_contract_test.dart`
- [X] T022 [P] [US1] Contract test for deactivate dependent in `../test/features/dependents/contracts/deactivate_dependent_contract_test.dart`
- [X] T023 [P] [US1] Integration test blocking 3rd active dependent when limit is 2 (RN-01) in `../test/features/dependents/integration/max_dependents_test.dart`
- [X] T024 [P] [US1] Integration test rejecting duplicate active dependent CPF across holders (RN-09) in `../test/features/dependents/integration/cpf_unique_test.dart`
- [X] T025 [P] [US1] Unit test for remaining uses calculation ignoring unvalidated appointments (RN-04, RN-05) in `../test/features/dependents/domain/dependent_quota_service_test.dart`
- [X] T026 [P] [US1] Widget test for dependent list/cadastro limit state in `../test/features/dependents/presentation/dependents_page_test.dart`

### Implementation for User Story 1

- [X] T027 [P] [US1] Implement cycle calculation service using holder subscription adhesion date (RN-06) in `../lib/features/dependents/domain/services/dependent_cycle_service.dart`
- [X] T028 [P] [US1] Implement quota service using `monthly_uses_per_dependent` and current cycle UsageRecord count (RN-02, RN-05) in `../lib/features/dependents/domain/services/dependent_quota_service.dart`
- [X] T029 [US1] Implement create dependent use case validating configurable limit and active CPF uniqueness (RN-01, RN-09) in `../lib/features/dependents/domain/usecases/create_dependent_usecase.dart`
- [X] T030 [P] [US1] Implement list dependents with remaining quota use case in `../lib/features/dependents/domain/usecases/get_dependents_usecase.dart`
- [X] T031 [P] [US1] Implement deactivate dependent use case in `../lib/features/dependents/domain/usecases/deactivate_dependent_usecase.dart`
- [X] T032 [US1] Implement Supabase datasource methods for create/list/deactivate dependents in `../lib/features/dependents/data/datasources/dependents_supabase_datasource.dart`
- [X] T033 [US1] Implement `DependentsBloc` events and states in `../lib/features/dependents/presentation/bloc/dependents_bloc.dart`
- [X] T034 [US1] Implement dependent cadastro/listagem page with limit reached, empty, loading, error, and success states in `../lib/features/dependents/presentation/pages/dependents_page.dart`
- [X] T035 [P] [US1] Implement dependent form widgets with CPF/date validation and accessible labels in `../lib/features/dependents/presentation/widgets/dependent_form.dart`
- [X] T036 [US1] Add navigation entry from profile or benefits area to dependents page in `../lib/features/profile/presentation/pages/profile_page.dart`

**Checkpoint**: User Story 1 is independently testable by managing dependents and verifying quota preview.

---

## Phase 4: User Story 2 - Agendar desconto para titular ou dependente (Priority: P1)

**Goal**: Cliente cria agendamento selecionando titular ou dependente sem debitar cota no agendamento.

**Independent Test**: Cliente selects a beneficiary, creates an appointment, receives an opaque signed QR token, and remaining quota stays unchanged until reception validation.

### Tests for User Story 2 (MANDATORY)

- [X] T037 [P] [US2] Contract test for create appointment with beneficiary selection in `../test/features/dependents/contracts/create_dependent_appointment_contract_test.dart`
- [X] T038 [P] [US2] Integration test proving appointment creation does not debit quota (RN-04, RN-05) in `../test/features/dependents/integration/schedule_no_debit_test.dart`
- [X] T039 [P] [US2] Integration test proving appointment cancellation does not alter quota (RN-04) in `../test/features/dependents/integration/cancel_no_quota_change_test.dart`
- [X] T040 [P] [US2] Unit test for opaque signed QR token generation without discount data (RN-08) in `../test/features/dependents/domain/qr_token_service_test.dart`
- [X] T041 [P] [US2] Widget test for beneficiary selector showing remaining quota and disabled exhausted beneficiaries in `../test/features/dependents/presentation/beneficiary_selector_test.dart`

### Implementation for User Story 2

- [X] T042 [P] [US2] Implement QR token service with opaque signed appointment identifier in `../lib/features/dependents/domain/services/qr_token_service.dart`
- [X] T043 [US2] Implement create appointment use case that creates `agendado`, signs QR token, and never creates UsageRecord (RN-04, RN-08) in `../lib/features/dependents/domain/usecases/create_dependent_appointment_usecase.dart`
- [X] T044 [P] [US2] Implement cancel appointment use case without quota effects in `../lib/features/dependents/domain/usecases/cancel_dependent_appointment_usecase.dart`
- [X] T045 [US2] Implement appointment datasource methods in `../lib/features/dependents/data/datasources/dependent_appointment_supabase_datasource.dart`
- [X] T046 [US2] Implement `DependentAppointmentBloc` events and states in `../lib/features/dependents/presentation/bloc/dependent_appointment_bloc.dart`
- [X] T047 [P] [US2] Implement "Para quem e esse desconto?" selector in `../lib/features/dependents/presentation/widgets/beneficiary_selector.dart`
- [X] T048 [P] [US2] Implement non-blocking warning for future appointments greater than or equal to quota in `../lib/features/dependents/presentation/widgets/future_appointments_quota_warning.dart`
- [X] T049 [US2] Integrate beneficiary selector into appointment/contact flow in `../lib/features/consultation/presentation/pages/consultation_schedule_page.dart`
- [X] T050 [US2] Integrate generated QR presentation for dependent appointment in `../lib/features/card/presentation/widgets/qr_code_sheet.dart`

**Checkpoint**: User Story 2 is independently testable by scheduling for a beneficiary without quota debit.

---

## Phase 5: User Story 3 - Validar QR na recepcao com debito atomico (Priority: P1)

**Goal**: Admin/reception validates QR and only then consumes one dependent usage, with atomicity, idempotency, status gates, and audit log.

**Independent Test**: Given one remaining use, two simultaneous scans of the same or competing QR cannot consume more than one quota; replay does not create a second UsageRecord; overdue holder or inactive dependent is blocked.

### Tests for User Story 3 (MANDATORY)

- [X] T051 [P] [US3] Contract test for QR validation RPC/datasource in `../test/features/dependents/contracts/qr_validate_contract_test.dart`
- [X] T052 [P] [US3] Integration test QR validation debits one use and decrements counter (RN-04, RN-05) in `../test/features/dependents/integration/qr_debits_quota_test.dart`
- [X] T053 [P] [US3] Integration test 3rd QR validation in same cycle is refused by quota limit (RN-02) in `../test/features/dependents/integration/quota_exhausted_test.dart`
- [X] T054 [P] [US3] Integration test two simultaneous scans with one remaining quota only allow one success (RN-07) in `../test/features/dependents/integration/concurrent_scan_test.dart`
- [X] T055 [P] [US3] Integration test QR replay for already used appointment is refused without new debit (RN-07, RN-08) in `../test/features/dependents/integration/qr_replay_test.dart`
- [X] T056 [P] [US3] Integration test blocking use when holder is overdue or dependent inactive (RN-10) in `../test/features/dependents/integration/status_gate_test.dart`
- [X] T057 [P] [US3] Integration test reset by holder adhesion cycle returns full quota (RN-06) in `../test/features/dependents/integration/cycle_reset_test.dart`
- [X] T058 [P] [US3] Unit test for cycle edges: adhesion day 31, short months, leap year, year turn in `../test/features/dependents/domain/dependent_cycle_service_test.dart`
- [X] T059 [P] [US3] Load/concurrency test for QR validation lock behavior in `../test/features/dependents/integration/qr_validation_load_test.dart`

### Implementation for User Story 3

- [X] T060 [US3] Add Supabase RPC `validate_dependent_qr` with transaction, signed token resolution, status gates, beneficiary lock, UsageRecord insert, appointment update, and idempotent replay handling in `../supabase/migrations/20260601_validate_dependent_qr_rpc.sql`
- [X] T061 [US3] Add audit log table/function support for QR validation approved/refused events in `../supabase/migrations/20260601_dependents_audit_log.sql`
- [X] T062 [US3] Implement QR validation use case mapping server result to domain result in `../lib/features/dependents/domain/usecases/validate_dependent_qr_usecase.dart`
- [X] T063 [US3] Implement QR validation datasource calling Supabase RPC in `../lib/features/dependents/data/datasources/qr_validation_supabase_datasource.dart`
- [X] T064 [US3] Implement `QrValidationBloc` events and states in `../lib/features/dependents/presentation/bloc/qr_validation_bloc.dart`
- [X] T065 [US3] Integrate dependent QR validation result into admin scanner page in `../lib/features/admin/presentation/pages/admin_qr_scanner_page.dart`
- [X] T066 [P] [US3] Implement admin QR result widgets for approved, refused, replay, exhausted quota, overdue holder, and inactive dependent in `../lib/features/dependents/presentation/widgets/qr_validation_result_card.dart`
- [X] T067 [US3] Ensure validation audit metadata includes actor, establishment, appointment, beneficiary, decision, reason, and timestamp in `../lib/features/dependents/data/models/qr_validation_result_model.dart`

**Checkpoint**: User Story 3 is independently testable through admin QR validation and quota/audit verification.

---

## Phase 6: User Story 4 - Configurar regras globais de dependentes (Priority: P2)

**Goal**: Admin autorizado/super admin can edit dependent settings without hardcoding limits.

**Independent Test**: Changing `max_dependents_per_holder` or `monthly_uses_per_dependent` updates create/list/quota behavior without code changes.

### Tests for User Story 4 (MANDATORY)

- [X] T068 [P] [US4] Unit test for reading default dependent settings when Supabase value is absent in `../test/core/services/clinic_settings_service_dependents_test.dart`
- [X] T069 [P] [US4] Integration test changing dependent settings changes create limit and quota calculation in `../test/features/dependents/integration/dependent_settings_test.dart`
- [X] T070 [P] [US4] Widget test for admin settings fields validation and save states in `../test/features/admin/presentation/dependent_settings_page_test.dart`

### Implementation for User Story 4

- [X] T071 [US4] Add typed getters/setters for dependent settings defaults in `../lib/core/services/clinic_settings_service.dart`
- [X] T072 [US4] Extend admin clinic settings page with `max_dependents_per_holder` and `monthly_uses_per_dependent` fields in `../lib/features/admin/presentation/pages/clinic_settings/admin_clinic_settings_page.dart`
- [X] T073 [P] [US4] Add numeric validation helpers for positive dependent settings in `../lib/core/utils/validators.dart`
- [X] T074 [US4] Ensure dependent use cases consume settings service values instead of constants in `../lib/features/dependents/domain/usecases/create_dependent_usecase.dart`
- [X] T075 [US4] Ensure quota service consumes settings service values instead of constants in `../lib/features/dependents/domain/services/dependent_quota_service.dart`

**Checkpoint**: User Story 4 is independently testable by changing settings and rerunning dependent/quota flows.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Hardening, documentation, routing, observability, and final validation across dependent flows.

- [X] T076 [P] Add scheduled expiration routine for stale `agendado` appointments without quota effects in `../supabase/migrations/20260601_expire_dependent_appointments.sql`
- [X] T077 [P] Add dependents route constants and navigation wiring in `../lib/main.dart`
- [X] T078 Add dependents DI registrations for all final BLoCs/use cases/repositories in `../lib/core/di/injection_container.dart`
- [X] T079 [P] Update feature documentation with flows, RN mapping, settings, QR validation, and failure states in `../docs/feature/dependentes.md`
- [X] T080 [P] Update Spec Kit quickstart with dependent test commands and manual validation in `specs/001-loyalty-card-app/quickstart.md`
- [X] T081 [P] Add accessibility review notes for dependents UI states in `../docs/feature/dependentes.md`
- [X] T082 [P] Add performance review notes for QR validation, list pagination, and duplicate Supabase calls in `../docs/feature/dependentes.md`
- [X] T083 Run `flutter analyze` from `../` (executed; currently reports pre-existing analyzer issues outside dependents scope)
- [X] T084 Run `flutter test` from `../`
- [ ] T085 Run Supabase migration validation locally or in staging for dependents migrations in `../supabase/migrations/` (blocked: local Supabase Postgres on `127.0.0.1:54322` is not running)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **US1 Dependents Management (Phase 3)**: Depends on Foundational.
- **US2 Appointment Beneficiary (Phase 4)**: Depends on US1 quota/list contracts and Foundational appointment entities.
- **US3 QR Validation (Phase 5)**: Depends on US1, US2, and Supabase schema/RPC foundations.
- **US4 Settings (Phase 6)**: Depends on Setup and Foundational; can run after US1 tests exist, but final behavior must be revalidated across US1/US3.
- **Polish (Phase 7)**: Depends on all desired user stories.

### User Story Dependencies

- **US1**: Independent MVP for cadastro/listagem/inativacao de dependentes.
- **US2**: Requires dependents and quota preview from US1.
- **US3**: Requires scheduled appointment and QR token from US2.
- **US4**: Cross-cutting; settings affect US1, US2, and US3.

### Within Each User Story

- Tests MUST be written and fail before implementation.
- Domain services/use cases before datasources and BLoCs.
- Datasources/repositories before presentation integration.
- Supabase RPC/transaction tasks before admin QR scanner integration.
- Story complete before moving to the next dependent story unless parallel team capacity is explicit.

---

## Parallel Opportunities

- Setup folder/test/doc tasks T002, T003, T004, T006, T007 can run in parallel.
- Foundational entity/repository/model contracts T009-T017 can run in parallel after T008 is drafted.
- US1 tests T020-T026 can run in parallel.
- US2 tests T037-T041 can run in parallel.
- US3 tests T051-T059 can run in parallel after QR contracts are agreed.
- US4 tests T068-T070 can run in parallel.
- Polish documentation and review tasks T079-T082 can run in parallel.

## Parallel Example: User Story 1

```bash
Task: "Contract test for create dependent in ../test/features/dependents/contracts/create_dependent_contract_test.dart"
Task: "Contract test for list dependents in ../test/features/dependents/contracts/list_dependents_contract_test.dart"
Task: "Integration test for max dependents in ../test/features/dependents/integration/max_dependents_test.dart"
Task: "Widget test for dependents page in ../test/features/dependents/presentation/dependents_page_test.dart"
```

## Parallel Example: User Story 3

```bash
Task: "Integration test for QR debit in ../test/features/dependents/integration/qr_debits_quota_test.dart"
Task: "Integration test for concurrent scan in ../test/features/dependents/integration/concurrent_scan_test.dart"
Task: "Integration test for QR replay in ../test/features/dependents/integration/qr_replay_test.dart"
Task: "Load test for QR lock behavior in ../test/features/dependents/integration/qr_validation_load_test.dart"
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete US1 with failing tests first, then implementation.
3. Validate dependent creation/list/deactivation and quota preview.
4. Stop and review before adding appointment and QR debit behavior.

### Incremental Delivery

1. US1: Dependents CRUD and quota preview.
2. US2: Beneficiary-aware appointment and signed QR without debit.
3. US3: Reception QR validation with atomic debit, idempotency, concurrency protection, and audit.
4. US4: Admin settings and no hardcoded limits.
5. Polish: expiration job, docs, accessibility, performance, analyze/test.

### Final Quality Gates

- All RN-01 to RN-10 have at least one automated test.
- No configurable limit is hardcoded.
- Appointment creation never creates UsageRecord.
- QR validation is server-side, atomic, idempotent, and audited.
- Admin scanner handles every refusal state with clear UI.
- `flutter analyze` passes.
- `flutter test` passes.
