# Backlog TDD - Vita Clube

> Prazo: 5 dias para fase de teste
> Metodologia: TDD (Red → Green → Refactor)
> Cada item: escrever teste PRIMEIRO, depois implementar

---

## Legenda
- [ ] Pendente
- [x] Concluído
- T = Teste | I = Implementação

---

## DIA 1 — Setup + Auth Supabase + Testes Auth

### 1.1 Setup Infraestrutura
- [x] T: `app_config_test.dart` — 3 ambientes (dev/staging/prod)
- [x] I: `AppConfig` com supabaseUrl, supabaseAnonKey, useSupabase
- [x] I: `SupabaseConfig` — inicialização condicional
- [x] I: `launch.json` — 3 configs de debug (Dev/Staging/Prod)
- [x] I: `pubspec.yaml` — supabase_flutter, bloc_test, mocktail
- [x] I: `main_staging.dart` — entry point staging
- [x] I: Corrigir Firebase nos entry points (dev/staging/prod)
- [x] I: `test/helpers/test_helpers.dart` — mocks centralizados

### 1.2 Testes Auth (FEITO)
- [x] T: `login_usecase_test.dart` — sucesso, credencial inválida, server error
- [x] T: `auth_bloc_test.dart` — campos, login, register, google, validação
- [ ] T: `register_usecase_test.dart` — sucesso, email duplicado, validação
- [ ] T: `google_signin_usecase_test.dart` — sucesso, cancelado, erro
- [ ] T: `auth_repository_impl_test.dart` — mock datasource → Either mapping

### 1.3 Auth Supabase DataSource
- [ ] T: `auth_supabase_datasource_test.dart`
  - login com email/senha → Supabase auth
  - register → Supabase auth + profile via trigger
  - Google Sign-In: GoogleSignIn → idToken → Supabase signInWithIdToken
  - logout → Supabase auth.signOut
  - getCurrentUser → Supabase auth.currentUser
- [ ] I: `auth_supabase_datasource.dart`
- [ ] I: Atualizar DI: `useMockData ? MockDataSource : SupabaseDataSource`

---

## DIA 2 — Home + Plans + Profile (Domain + Data + BLoC + Testes)

### 2.1 Home Feature
**Domain:**
- [ ] T: `get_plan_status_usecase_test.dart` — retorna status do plano do user
- [ ] T: `get_user_consultations_usecase_test.dart` — lista consultas do user
- [ ] I: UseCases + Repository interface

**Data:**
- [ ] T: `home_repository_impl_test.dart` — mapeia datasource → entities
- [ ] I: `HomeSupabaseDataSource` — queries em `subscriptions`, `consultations`, `profiles`
- [ ] I: `HomeRepositoryImpl`

**Presentation:**
- [ ] T: `home_bloc_test.dart` — load, refresh, error states
- [ ] I: `HomeBloc` — events: LoadHome, RefreshHome
- [ ] I: Conectar `HomePage` ao BLoC (remover hardcoded)

### 2.2 Plans Feature
**Domain:**
- [ ] T: `get_plans_usecase_test.dart` — lista planos ativos
- [ ] T: `subscribe_to_plan_usecase_test.dart` — cria subscription
- [ ] I: UseCases + Repository interface

**Data:**
- [ ] T: `plans_repository_impl_test.dart`
- [ ] I: `PlansSupabaseDataSource` — queries em `plans`, `plan_benefits`, `subscriptions`
- [ ] I: `PlansRepositoryImpl`

**Presentation:**
- [ ] T: `plans_bloc_test.dart` — load plans, subscribe, error
- [ ] I: `PlansBloc`
- [ ] I: Conectar `PlanPage`/`ChoosePlanPage` ao BLoC

### 2.3 Profile Feature
**Domain:**
- [ ] T: `get_profile_usecase_test.dart` — retorna dados decriptados
- [ ] T: `update_profile_usecase_test.dart` — atualiza nome, telefone
- [ ] I: UseCases + Repository interface

**Data:**
- [ ] T: `profile_repository_impl_test.dart`
- [ ] I: `ProfileSupabaseDataSource` — CRUD em `profiles` (decrypt CPF/phone)
- [ ] I: `ProfileRepositoryImpl`

**Presentation:**
- [ ] T: `profile_bloc_test.dart` — load, update, error
- [ ] I: `ProfileBloc`
- [ ] I: Conectar `ProfilePage`/`PersonalDataPage` ao BLoC

---

## DIA 3 — Card + Payments + Professionals + Notifications

### 3.1 Card Feature
**Domain:**
- [ ] T: `get_member_card_usecase_test.dart` — dados do cartão + QR data
- [ ] I: UseCases + Entity + Repository interface

**Data:**
- [ ] T: `card_repository_impl_test.dart`
- [ ] I: `CardSupabaseDataSource` — query profile + subscription + badge
- [ ] I: `CardRepositoryImpl`

**Presentation:**
- [ ] T: `card_bloc_test.dart` — load card data
- [ ] I: `CardBloc`
- [ ] I: Conectar `CardPage` ao BLoC

### 3.2 Payments Feature
**Domain:**
- [ ] T: `get_payments_usecase_test.dart` — histórico do user
- [ ] T: `cancel_subscription_usecase_test.dart` — cancela + motivo
- [ ] I: UseCases + Repository interface

**Data:**
- [ ] T: `payments_repository_impl_test.dart`
- [ ] I: `PaymentsSupabaseDataSource` — queries `payments`, `subscriptions`
- [ ] I: `PaymentsRepositoryImpl`

**Presentation:**
- [ ] T: `payments_bloc_test.dart` — load, cancel, error
- [ ] I: `PaymentsBloc`
- [ ] I: Conectar `PaymentsPage`/`CancellationPage` ao BLoC

### 3.3 Professionals Feature
**Domain:**
- [ ] T: `get_professionals_usecase_test.dart` — lista com filtro por specialty
- [ ] I: UseCases + Entity + Repository interface

**Data:**
- [ ] T: `professionals_repository_impl_test.dart`
- [ ] I: `ProfessionalsSupabaseDataSource` — join professionals + specialties
- [ ] I: `ProfessionalsRepositoryImpl`

**Presentation:**
- [ ] T: `professionals_bloc_test.dart` — load, filter, search
- [ ] I: `ProfessionalsBloc`
- [ ] I: Conectar `ProfessionalsPage` ao BLoC

### 3.4 Notifications Feature
**Domain:**
- [ ] T: `get_notifications_usecase_test.dart` — lista do user
- [ ] T: `mark_notification_read_usecase_test.dart` — marca como lida
- [ ] I: UseCases + Repository interface

**Data:**
- [ ] T: `notifications_repository_impl_test.dart`
- [ ] I: `NotificationsSupabaseDataSource` — CRUD em `notifications`
- [ ] I: `NotificationsRepositoryImpl`

**Presentation:**
- [ ] T: `notifications_bloc_test.dart` — load, mark read, count unread
- [ ] I: `NotificationsBloc`
- [ ] I: Conectar `NotificationsPage` ao BLoC

---

## DIA 4 — Sorteios + Migrar Admin/Referral/Badge

### 4.1 Sorteio Feature (user-side)
**Domain:**
- [ ] T: `get_draws_user_usecase_test.dart` — sorteios disponíveis
- [ ] T: `participate_in_draw_usecase_test.dart` — inscrever, validar elegibilidade
- [ ] I: UseCases + Repository interface

**Data:**
- [ ] T: `draws_user_repository_impl_test.dart`
- [ ] I: `DrawsUserSupabaseDataSource` — `draws` + `draw_participants`
- [ ] I: `DrawsUserRepositoryImpl`

**Presentation:**
- [ ] T: `draws_user_bloc_test.dart` — load, participate, check eligibility
- [ ] I: `DrawsUserBloc`
- [ ] I: Conectar `SorteioPage` ao BLoC

### 4.2 Migrar Mock → Supabase (Admin)
- [ ] T: `admin_supabase_datasource_test.dart` — CRUD genérico
- [ ] I: `AdminSupabaseDataSource` — implementar interface existente
- [ ] I: Atualizar DI: mock vs supabase por ambiente

### 4.3 Migrar Mock → Supabase (Referral + Badge Progress)
- [ ] T: `referral_supabase_datasource_test.dart`
- [ ] I: `ReferralSupabaseDataSource`
- [ ] T: `badge_progress_supabase_datasource_test.dart`
- [ ] I: `BadgeProgressSupabaseDataSource`

---

## DIA 5 — Testes E2E + Integração + Polish

### 5.1 Testes de Integração
- [ ] T: Fluxo completo: Register → Login → Home → Ver plano
- [ ] T: Fluxo: Escolher plano → Assinatura → Badge progress
- [ ] T: Fluxo: Indicação → Validação → Claim reward
- [ ] T: Fluxo: Sorteio → Participar → Verificar resultado

### 5.2 Testes de Serviços (já implementados, sem testes)
- [ ] T: `subscription_guard_test.dart` — bloqueio por inadimplência
- [ ] T: `consultation_limit_service_test.dart` — limites por badge
- [ ] T: `discount_service_test.dart` — descontos por badge
- [ ] T: `grace_period_service_test.dart` — carência 7 dias

### 5.3 Validação RLS
- [ ] T: User não acessa dados de outro user
- [ ] T: Admin acessa todos os dados
- [ ] T: Financeiro só lê payments/subscriptions/coupons/profiles

### 5.4 Polish
- [ ] Remover pastas `/bloc/` duplicadas (auth, splash, onboarding)
- [ ] Registrar OnboardingBloc no DI
- [ ] Tratar estados de erro de rede em todas as features
- [ ] Build APK de teste
- [ ] Smoke test em device real

---

## Contagem de Testes Estimada

| Camada | Qtd Testes |
|--------|-----------|
| Core (config, services) | ~10 |
| Domain (usecases) | ~25 |
| Data (repositories) | ~15 |
| Presentation (blocs) | ~30 |
| Integração | ~10 |
| **Total** | **~90** |

---

## Regras TDD do Projeto

1. **Red**: Escrever teste que falha
2. **Green**: Implementar o mínimo para passar
3. **Refactor**: Limpar sem quebrar testes
4. **Rodar testes**: `flutter test` após cada implementação
5. **Nomear testes**: `deve [ação] quando [condição]`
6. **Mocks**: Usar `mocktail` (não mockito)
7. **BLoC tests**: Usar `bloc_test` com `blocTest<B, S>()`
8. **Cobertura**: `flutter test --coverage` ao final de cada dia
