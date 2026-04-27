# Feature Parceiro (Partner) — Plano de Implementação

## Visão Geral

O Vita Clube precisa de uma funcionalidade de **parceiros** (laboratórios, clínicas, farmácias, óticas). O parceiro cadastra seus serviços/exames e preços. O usuário visualiza os parceiros, seus serviços, e faz **check-in para validar desconto**.

### Validação com Dois Fatores

A validação exige **dois fatores**: token do usuário + código do parceiro — só registra uso quando ambos conferem.

```
1. Usuário abre Parceiros → escolhe lab → "Gerar Token" → app mostra OTP 6 dígitos (5 min)
2. Usuário mostra tela pro atendente
3. Atendente fala o código do balcão (ex: "LABSAUDE")
4. Usuário digita o código no app → app valida token + código
5. Tela muda pra "DESCONTO VALIDADO" → registro salvo no banco
6. Se não digitar código, token expira sem registro
```

### Nova Role: `parceiro`

O parceiro loga no app e vê somente o dashboard dele (serviços, validações, código).

---

## Arquitetura

Segue a **Clean Architecture + BLoC** do projeto:

```
lib/features/parceiro/
├── domain/
│   ├── entities/         # PartnerEntity, PartnerServiceEntity, PartnerValidationEntity
│   ├── repositories/     # Interfaces (contratos)
│   └── usecases/         # 11 use cases
├── data/
│   ├── models/           # DTOs com fromJson/toJson
│   ├── datasources/      # Mock (depois Remote)
│   └── repositories/     # Implementações
└── presentation/
    ├── bloc/             # 3 BLoCs (service, validation, checkin)
    ├── pages/            # 5 páginas parceiro + 3 páginas usuário
    └── widgets/          # Componentes reutilizáveis
```

---

## Fase 1 — Schema SQL

**Arquivo:** `supabase/schema.sql`

### Alterações

| Item | Descrição |
|------|-----------|
| Enum `user_role` | Adicionar `'parceiro'` |
| Enum `partner_category` | `'laboratorio', 'clinica', 'farmacia', 'otica', 'outro'` |
| Tabela `partners` | id, profile_id, name, category, code (UNIQUE), address, phone_encrypted, logo_url, is_active, timestamps |
| Tabela `partner_services` | id, partner_id, name, description, original_price, discounted_price, is_active, timestamps |
| Tabela `partner_validations` | id, partner_id, user_id, service_id, user_name, user_badge_level, discount_applied, service_name, validated_at |
| Função `is_parceiro()` | Helper RLS |
| RLS Policies | Parceiro: próprios dados; Users: SELECT ativos; Admin: ALL |

---

## Fase 2 — Domain Layer

### Entities (4 arquivos)

| Entity | Campos Principais |
|--------|-------------------|
| `PartnerEntity` | id, profileId, name, category, code, address, phone, logoUrl, isActive |
| `PartnerServiceEntity` | id, partnerId, name, description, originalPrice, discountedPrice, isActive |
| `PartnerValidationEntity` | id, partnerId, userId, userName, userBadgeLevel, discountApplied, serviceId, serviceName, validatedAt |

### Repository Interfaces (3 arquivos)

| Repository | Métodos |
|------------|---------|
| `PartnerRepository` | getAll(), getByProfileId(), update(), regenerateCode() |
| `PartnerServiceRepository` | getByPartnerId(), getAllActive(), create(), update(), delete() |
| `PartnerValidationRepository` | getByPartnerId(), validateCheckin(), generateToken() |

### Use Cases (11 arquivos)

**Partner:** GetPartnersUseCase, GetPartnerByProfileUseCase, UpdatePartnerUseCase, RegenerateCodeUseCase

**PartnerService:** GetPartnerServicesUseCase, GetAllActiveServicesUseCase, CreatePartnerServiceUseCase, UpdatePartnerServiceUseCase, DeletePartnerServiceUseCase

**PartnerValidation:** GetPartnerValidationsUseCase, ValidateCheckinUseCase, GenerateTokenUseCase

---

## Fase 3 — Data Layer

### Models (3 arquivos)

`PartnerModel`, `PartnerServiceModel`, `PartnerValidationModel` — extendem entity, factory fromJson/toJson/fromEntity.

### Mock DataSource (1 arquivo)

- Interface `ParceiroDataSource`
- `ParceiroMockDataSource` com:
  - 3 parceiros mock (Lab Vita Saúde, Clínica Bem Estar, Ótica VitaVision)
  - 6 serviços mock
  - 8 validações mock
  - Lógica de token OTP 6 dígitos com TTL 5 min

### Repository Impls (3 arquivos)

try/catch ServerException → Left(ServerFailure)

---

## Fase 4 — Presentation Layer

### BLoCs (3 BLoCs × 3 arquivos = 9 arquivos)

| BLoC | Events | States |
|------|--------|--------|
| `PartnerServiceBloc` | Load, Search, Create, Update, Delete | items, filteredItems, searchQuery, status |
| `PartnerValidationBloc` | LoadValidations, SearchValidations | items, filteredItems, status |
| `PartnerCheckinBloc` | GenerateToken, SubmitPartnerCode | tokenValue, expiresAt, status (initial/tokenGenerated/validating/validated/failure) |

### Páginas Parceiro (5 arquivos)

| Página | Descrição |
|--------|-----------|
| `ParceiroDashboardPage` | Métricas + cards (Serviços, Validações, Meu Código) + logout |
| `PartnerServicesListPage` | Lista com search + FAB para criar |
| `PartnerServiceFormPage` | Form create/edit |
| `PartnerValidationsListPage` | Lista readonly com search |
| `PartnerCodePage` | Código do parceiro + botão "Regenerar" |

### Páginas Usuário (3 arquivos)

| Página | Descrição |
|--------|-----------|
| `PartnersListPage` | Lista parceiros ativos com logo, nome, categoria |
| `PartnerDetailPage` | Info + serviços/preços + botão "Check-in" |
| `PartnerCheckinPage` | Step 1: Gerar Token → Step 2: Digitar código → Step 3: Resultado |

### Widgets (2 arquivos)

| Widget | Descrição |
|--------|-----------|
| `ParceiroMetricCard` | Card de métrica (padrão FinanceiroMetricCard) |
| `OtpDisplayWidget` | Código 6 dígitos grande + timer regressivo |

---

## Fase 5 — Routing e Auth

### Arquivos Modificados

| Arquivo | Mudança |
|---------|---------|
| `splash_state.dart` | Adicionar `SplashNavigateToPartner` |
| `splash_bloc.dart` | Checar `role == 'parceiro'` → emit SplashNavigateToPartner |
| `splash_page.dart` | Handler → ParceiroDashboardPage |
| `login_page.dart` | Adicionar `case 'parceiro'` no switch |
| `auth_mock_datasource.dart` | Mock: `parceiro@vitaclube.com` / `parceiro123` |

---

## Fase 6 — DI e Integração

### Arquivos Modificados

| Arquivo | Mudança |
|---------|---------|
| `injection_container.dart` | Registrar: DataSource, 3 repos, 11 usecases, 3 BLoCs |
| `test_helpers.dart` | Adicionar 3 Mock repositories |
| `home_page.dart` | Card "Parceiros" nos quick actions |
| `financeiro_dashboard_page.dart` | Card "Parceiros" na seção Gestão |

---

## Ordem de Implementação

| Step | O que | Arquivos |
|------|-------|----------|
| 1 | Schema SQL | 1 modificado |
| 2 | Domain entities | 4 novos |
| 3 | Domain repo interfaces | 3 novos |
| 4 | Domain usecases | 11 novos |
| 5 | Data models | 3 novos |
| 6 | Data mock datasource | 1 novo |
| 7 | Data repo impls | 3 novos |
| 8 | Presentation BLoCs | 9 novos |
| 9 | Presentation widgets | 2 novos |
| 10 | Presentation pages parceiro | 5 novos |
| 11 | Presentation pages usuário | 3 novos |
| 12-14 | Auth + Routing | 5 modificados |
| 15-18 | DI + Integração | 4 modificados |

**Total: ~47 arquivos novos + 8 arquivos modificados**

---

## Verificação

```bash
flutter analyze    # zero errors
flutter test       # todos os testes passando
```

### Testes Manuais

- [ ] Login `parceiro@vitaclube.com` / `parceiro123` → ParceiroDashboardPage
- [ ] CRUD de serviços no dashboard parceiro
- [ ] Login `teste@vitaclube.com` / `123456` → Home → Parceiros → ver labs → check-in
- [ ] Gerar token → digitar código → validação registrada
- [ ] Token expirado → erro
- [ ] Código errado → erro

---

## Backend (Supabase)

- **Supabase** = banco (PostgreSQL), auth, RLS
- **Firebase** = APENAS Google Sign-In
- Dados sensíveis (telefone) criptografados com pgcrypto
- RLS policies protegem acesso por role
