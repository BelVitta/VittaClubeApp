# SDD — QR Code Validation Flow with Discount Calculation
**Data:** 2026-06-05  
**Branch alvo:** a partir de `002-pix-auto-subscription`  
**Escopo:** Tornar o fluxo QR completamente funcional — exibição real no cliente, validação real no admin, cálculo e registro de desconto por consulta.

---

## 1. SPECIFY

### 1.1 Contexto e Problema

O núcleo do produto é o binômio: **membro mostra QR → admin valida e aplica desconto**. Hoje isso está 100% simulado:

| Ponto | Estado atual | Estado alvo |
|---|---|---|
| QR na carteirinha | Hardcoded `'53465123'` | `userId` real do Supabase Auth |
| Nome na carteirinha | Hardcoded `'Diana Santos'` | Nome real do `ProfileBloc` |
| Admin "Validar Desconto" | Sempre retorna aprovado (fake) | Chama RPC `validate_member_qr` no Supabase |
| Valor da consulta | Não existe | Admin informa; sistema calcula desconto |
| Economia exibida | Não existe | Valor poupado em R$ exibido ao admin e no histórico |
| Consulta registrada | Não existe neste fluxo | Gravada em `consultations` com todos os campos de desconto |

---

### 1.2 User Stories

**US-01 — Membro / Carteirinha**  
> Como membro ativo, quero ver o meu QR Code real na carteirinha para que o admin da clínica possa escanear e validar meu benefício.

Critérios de aceite:
- A carteirinha exibe meu nome completo (da tabela `profiles`)
- O QR Code codifica meu `userId` (UUID do Supabase Auth)
- O botão "Mostrar QR Code" só fica habilitado se `subscription.canUseQr == true`
- Ao copiar o código, o campo exibe os primeiros 8 caracteres do UUID formatados

---

**US-02 — Admin / Scanner**  
> Como admin, quero escanear o QR de um membro e ver imediatamente se ele está apto a receber desconto, qual é o nível do plano e qual é o percentual de desconto aplicável.

Critérios de aceite:
- O scanner lê o QR e chama o Supabase (não aprova local)
- O resultado mostra: nome do membro, nível do plano, % desconto, usos restantes no ciclo
- Em caso de recusa (inadimplente, QR inválido, cota esgotada), exibe mensagem clara com motivo
- O botão "Validar Desconto" só aparece se `decision == approved`

---

**US-03 — Admin / Valor da Consulta + Desconto**  
> Como admin, após a aprovação do QR, quero informar o valor original da consulta e ter o sistema calcular automaticamente o desconto, mostrando quanto o membro economizou.

Critérios de aceite:
- Campo numérico para valor da consulta (ex: R$ 150,00)
- Preview em tempo real: valor original, desconto (%), valor do desconto em R$, valor final
- Ao confirmar: consulta é registrada com todos esses campos
- Admin vê confirmação de sucesso com resumo

---

**US-04 — Membro / Histórico**  
> Como membro, quero ver no meu histórico de uso quanto economizei em cada consulta validada.

Critérios de aceite:
- Histórico exibe: local/especialidade, data, valor original, desconto aplicado, valor final
- Total acumulado de economia visível

---

### 1.3 Data Contracts

#### QR Payload (membro → admin)
```
Tipo: String plana
Conteúdo: userId (UUID v4 do Supabase Auth)
Exemplo: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

#### Supabase RPC — `validate_member_qr`
```sql
-- Input
p_user_id        UUID    -- userId lido do QR
p_actor_user_id  UUID    -- userId do admin que está validando

-- Output (JSONB)
{
  "decision":           "approved" | "refused" | "overdue_holder" | "invalid_token" | "quota_exhausted",
  "message":            "Membro ativo. Desconto de 15% aplicável.",
  "member_name":        "Diana Santos",
  "plan_level":         "prata",
  "discount_percentage": 15.0,
  "remaining_uses":     3,
  "subscription_id":    "uuid"
}
```

#### Tabela `consultations` — novos campos
```sql
original_value      NUMERIC(10,2)  -- valor cheio informado pelo admin
discount_percentage NUMERIC(5,2)   -- % do nível do membro
discount_amount     NUMERIC(10,2)  -- economia em R$
final_value         NUMERIC(10,2)  -- valor cobrado ao membro
validated_by        UUID           -- admin que validou (FK auth.users)
validated_at        TIMESTAMPTZ    -- momento da validação
```

---

## 2. PLAN

### 2.1 Decisões Arquiteturais

| Decisão | Escolha | Justificativa |
|---|---|---|
| Formato do QR da carteirinha | `userId` puro (UUID string) | MVP simples; a validação de segurança fica no RLS do Supabase |
| Fonte do percentual de desconto | RPC retorna `discount_percentage` consultando a tabela `badges` | Centraliza a regra no banco; `DiscountService` calcula os valores em R$ |
| Dois tipos de QR no scanner | UUID = carteirinha; `base64.xxx` = dependente | Distinção pelo formato da string ao ler o QR |
| Onde calcular o desconto | Flutter (`DiscountService`) após receber o `discount_percentage` do RPC | Cálculo é trivial; evita round-trip extra |
| Registro da consulta | Nova chamada `consultations.insert()` no `AdminSupabaseDataSource` | Usa datasource já registrado no DI |
| `QrTokenService` secret | Ler de `AppConfig` / `--dart-define` por ambiente | Corrige vulnerabilidade; sem mudar o contrato do serviço |

### 2.2 Mapa de Mudanças por Camada

```
Supabase (backend)
  ├── NOVA migration: alter table consultations add columns
  ├── NOVA RPC: validate_member_qr
  └── RLS: validate_member_qr acessível apenas para admins

Domain (Dart puro)
  ├── MODIFICAR QrValidationResult: + memberName, planLevel, discountPercentage
  ├── NOVO ValidateMemberQrUseCase
  ├── NOVO MemberQrValidationRepository (interface)
  └── NOVO RecordConsultationUseCase (ou reusar existing)

Data
  ├── MODIFICAR QrValidationResultModel.fromJson: novos campos
  ├── NOVO MemberQrValidationDataSource (interface)
  ├── MODIFICAR DependentsSupabaseDataSource: adicionar validateMemberQr()
  └── MODIFICAR ConsultationModel: novos campos de desconto

Presentation
  ├── MODIFICAR CardPage: usar ProfileBloc + SubscriptionBloc
  ├── MODIFICAR AdminQrScannerPage: usar QrValidationBloc (real)
  ├── NOVO ConsultationValueSheet: input valor + preview desconto
  ├── MODIFICAR QrValidationResultCard: exibir memberName, planLevel, discountPercentage
  └── MODIFICAR ConsultationHistoryItem: exibir economia

DI
  ├── MODIFICAR QrTokenService: secret via AppConfig
  └── NOVO ValidateMemberQrUseCase registrado
```

### 2.3 Fluxo Admin End-to-End (após as mudanças)

```
[Admin abre scanner]
       ↓
[Câmera lê QR]
       ↓
[_onDetect: detecta tipo do QR]
  ├── UUID puro → ValidateMemberQrUseCase(userId, actorUserId)
  └── base64.sig → ValidateDependentQrUseCase(token, actorUserId)
       ↓
[QrValidationBloc emite loading → completed/failure]
       ↓
[_MemberValidationSheet exibe resultado real]
  ├── Recusado → QrValidationResultCard (vermelho, motivo)
  └── Aprovado → mostra nome, nível, %, + botão "Informar valor"
       ↓
[ConsultationValueSheet]
  ├── Admin digita R$ 150,00
  ├── Preview: "Desconto 15% → R$ 22,50 → Final R$ 127,50"
  └── Confirmar → RecordConsultationUseCase → consultations.insert()
       ↓
[SuccessSheet: "Desconto aplicado! Membro economizou R$ 22,50"]
```

---

## 3. TASKS

### Phase 0 — Supabase Backend (pré-requisito de tudo)

**Tarefa 0.1 — Migration: novos campos em `consultations`**
```sql
-- Arquivo: supabase/migrations/YYYYMMDD_consultation_discount_fields.sql
ALTER TABLE consultations
  ADD COLUMN IF NOT EXISTS original_value      NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS discount_percentage NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS discount_amount     NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS final_value         NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS validated_by        UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS validated_at        TIMESTAMPTZ;
```

**Tarefa 0.2 — RPC `validate_member_qr`**
```sql
-- Arquivo: supabase/migrations/YYYYMMDD_validate_member_qr_rpc.sql
CREATE OR REPLACE FUNCTION validate_member_qr(
  p_user_id        UUID,
  p_actor_user_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sub       RECORD;
  v_profile   RECORD;
  v_badge     RECORD;
  v_discount  NUMERIC := 0;
BEGIN
  -- Busca perfil do membro
  SELECT name INTO v_profile FROM profiles WHERE id = p_user_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('decision','invalid_token','message','Usuário não encontrado.');
  END IF;

  -- Busca assinatura ativa
  SELECT * INTO v_sub
    FROM subscriptions
   WHERE user_id = p_user_id
     AND is_current = true
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('decision','refused','message','Sem assinatura ativa.','member_name', v_profile.name);
  END IF;

  -- Checa inadimplência
  IF v_sub.payment_access_status = 'blocked' THEN
    RETURN jsonb_build_object('decision','overdue_holder','message','Assinatura com pagamento pendente.','member_name',v_profile.name);
  END IF;

  -- Busca desconto do badge
  SELECT discount_percentage INTO v_badge
    FROM badges
   WHERE level_name = v_sub.plan_level_status
  LIMIT 1;
  v_discount := COALESCE(v_badge.discount_percentage, 0);

  RETURN jsonb_build_object(
    'decision',            'approved',
    'message',             'Membro ativo. Desconto de ' || v_discount || '% aplicável.',
    'member_name',         v_profile.name,
    'plan_level',          v_sub.plan_level_status,
    'discount_percentage', v_discount,
    'subscription_id',     v_sub.id
  );
END;
$$;

-- Permissão: apenas service_role e funções internas
REVOKE ALL ON FUNCTION validate_member_qr FROM PUBLIC;
GRANT EXECUTE ON FUNCTION validate_member_qr TO authenticated;
```

**Verificação Phase 0:**
- [ ] `supabase db push` sem erros
- [ ] Testar RPC no Studio com UUID de usuário ativo → retorna `"approved"`
- [ ] Testar com usuário inexistente → retorna `"invalid_token"`
- [ ] Testar com usuário inadimplente → retorna `"overdue_holder"`

---

### Phase 1 — Domain Layer (Dart puro)

**Tarefa 1.1 — Estender `QrValidationResult`**  
Arquivo: `lib/features/dependents/domain/repositories/qr_validation_repository.dart`

Adicionar campos:
```dart
final String? memberName;
final String? planLevel;
final double? discountPercentage;
final String? subscriptionId;
```

**Tarefa 1.2 — Novo `MemberQrValidationRepository` (interface)**  
Arquivo: `lib/features/dependents/domain/repositories/member_qr_validation_repository.dart`

```dart
abstract class MemberQrValidationRepository {
  Future<Either<Failure, QrValidationResult>> validateMemberQr({
    required String userId,
    required String actorUserId,
  });
}
```

**Tarefa 1.3 — Novo `ValidateMemberQrUseCase`**  
Arquivo: `lib/features/dependents/domain/usecases/validate_member_qr_usecase.dart`

```dart
class ValidateMemberQrParams extends Equatable {
  final String userId;
  final String actorUserId;
  // ...
}

class ValidateMemberQrUseCase {
  final MemberQrValidationRepository repository;
  Future<Either<Failure, QrValidationResult>> call(ValidateMemberQrParams params);
}
```

**Tarefa 1.4 — Novo `RecordConsultationParams` e UseCase**  
Arquivo: `lib/features/consultation/domain/usecases/record_consultation_usecase.dart`

```dart
class RecordConsultationParams {
  final String userId;        // membro
  final String validatedBy;  // admin
  final double originalValue;
  final double discountPercentage;
  // discount_amount e final_value calculados aqui
}
```

**Verificação Phase 1:**
- [ ] `flutter analyze` sem erros
- [ ] Nenhuma dependência de Flutter nos arquivos domain

---

### Phase 2 — Data Layer

**Tarefa 2.1 — Estender `QrValidationResultModel.fromJson`**  
Arquivo: `lib/features/dependents/data/models/qr_validation_result_model.dart`

```dart
memberName: json['member_name'] as String?,
planLevel: json['plan_level'] as String?,
discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
subscriptionId: json['subscription_id'] as String?,
```

**Tarefa 2.2 — `MemberQrValidationDataSource` interface + implementação**  
Interface: `lib/features/dependents/data/datasources/dependents_datasource.dart` (adicionar)  
Implementação em `DependentsSupabaseDataSource`:

```dart
Future<Map<String, dynamic>> validateMemberQr({
  required String userId,
  required String actorUserId,
}) async {
  final result = await _client.rpc('validate_member_qr', params: {
    'p_user_id': userId,
    'p_actor_user_id': actorUserId,
  });
  return Map<String, dynamic>.from(result as Map);
}
```

**Tarefa 2.3 — `MemberQrValidationRepositoryImpl`**  
Arquivo: `lib/features/dependents/data/repositories/member_qr_validation_repository_impl.dart`

**Tarefa 2.4 — Estender `ConsultationModel` com campos de desconto**  
Arquivo: `lib/features/consultation/data/models/consultation_model.dart`

Adicionar campos opcionais: `originalValue`, `discountPercentage`, `discountAmount`, `finalValue`, `validatedBy`, `validatedAt`

**Tarefa 2.5 — `ConsultationSupabaseDataSource.recordConsultation()`**  
Arquivo: `lib/features/consultation/data/datasources/consultation_supabase_datasource.dart`

```dart
Future<void> recordConsultation({
  required String userId,
  required String validatedBy,
  required double originalValue,
  required double discountPercentage,
}) async {
  final discountAmount = originalValue * discountPercentage / 100;
  final finalValue = originalValue - discountAmount;
  await _supabase.from('consultations').insert({
    'user_id': userId,
    'validated_by': validatedBy,
    'original_value': originalValue,
    'discount_percentage': discountPercentage,
    'discount_amount': discountAmount,
    'final_value': finalValue,
    'validated_at': DateTime.now().utc.toIso8601String(),
    'status': 'realizado',
  });
}
```

**Verificação Phase 2:**
- [ ] `flutter analyze` sem erros
- [ ] Unit test: `QrValidationResultModel.fromJson` com novos campos

---

### Phase 3 — DI + CartãoPage

**Tarefa 3.1 — Registrar novos artefatos no DI**  
Arquivo: `lib/core/di/injection_container.dart`

```dart
// Adicionar após QrValidationRepository:
sl.registerLazySingleton<MemberQrValidationRepository>(
  () => MemberQrValidationRepositoryImpl(dataSource: sl()),
);
sl.registerLazySingleton(() => ValidateMemberQrUseCase(sl()));
sl.registerLazySingleton(() => RecordConsultationUseCase(sl()));

// Corrigir QrTokenService:
sl.registerLazySingleton(
  () => QrTokenService(
    secretProvider: () async => AppConfig.instance.qrSecret,
  ),
);
```

**Tarefa 3.2 — Adicionar `qrSecret` ao `AppConfig`**  
Arquivo: `lib/core/config/app_config.dart`

```dart
String get qrSecret => _env('QR_SECRET', fallback: 'local-dev-qr-secret');
```

**Tarefa 3.3 — Corrigir `CardPage` — dados reais**  
Arquivo: `lib/features/card/presentation/pages/card_page.dart`

- Remover `_memberName` e `_memberCode` hardcoded
- Adicionar `ProfileBloc` ao `BlocProvider`
- Ler `profile.name` e `profile.id` dos estados
- Passar `profile.id` para `QrCodeSheet.show(memberCode: profile.id)`
- Exibir os 8 primeiros chars do UUID formatados como código de exibição:
  ```dart
  String _formatDisplayCode(String id) => id.replaceAll('-', '').substring(0, 8).toUpperCase();
  ```

**Verificação Phase 3:**
- [ ] Carteirinha exibe nome real do usuário logado
- [ ] QR gerado contém o `userId` real
- [ ] Código de exibição mostra 8 chars do UUID

---

### Phase 4 — Admin Scanner com Validação Real

**Tarefa 4.1 — Detecção de tipo de QR**  
Arquivo: `lib/features/admin/presentation/pages/admin_qr_scanner_page.dart`

```dart
bool _isMemberCardQr(String code) {
  // UUID v4 pattern: 8-4-4-4-12 chars hex
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  return uuidRegex.hasMatch(code);
}

void _onDetect(BarcodeCapture capture) {
  // ...
  final code = barcode.rawValue!;
  if (_isMemberCardQr(code)) {
    _showMemberSheet(code);      // → validate_member_qr
  } else {
    _showAppointmentSheet(code); // → validate_dependent_qr (existente)
  }
}
```

**Tarefa 4.2 — Integrar `QrValidationBloc` no scanner**  
Adicionar `BlocProvider<QrValidationBloc>` ao `AdminQrScannerPage`.  
No `_MemberValidationSheet`, disparar evento e reagir ao estado:

```dart
// Ao abrir o sheet:
context.read<QrValidationBloc>().add(ValidateMemberQrRequested(
  userId: memberCode,
  actorUserId: supabase.auth.currentUser!.id,
));

// Builder:
BlocBuilder<QrValidationBloc, QrValidationState>(
  builder: (ctx, state) {
    if (state.status == QrValidationStatus.loading) return CircularProgressIndicator();
    if (state.status == QrValidationStatus.failure) return ErrorWidget(state.errorMessage);
    if (state.status == QrValidationStatus.completed) {
      return _buildApprovedOrRefusedView(state.result!);
    }
    return SizedBox.shrink();
  },
)
```

**Tarefa 4.3 — Adicionar `ValidateMemberQrRequested` event ao BLoC**  
Arquivo: `lib/features/dependents/presentation/bloc/qr_validation_event.dart`

```dart
class ValidateMemberQrRequested extends QrValidationEvent {
  final String userId;
  final String actorUserId;
  // ...
}
```

Arquivo: `lib/features/dependents/presentation/bloc/qr_validation_bloc.dart`

```dart
on<ValidateMemberQrRequested>(_onValidateMember);

Future<void> _onValidateMember(
  ValidateMemberQrRequested event,
  Emitter<QrValidationState> emit,
) async {
  emit(state.copyWith(status: QrValidationStatus.loading));
  final result = await validateMemberQrUseCase(ValidateMemberQrParams(
    userId: event.userId,
    actorUserId: event.actorUserId,
  ));
  result.fold(
    (f) => emit(state.copyWith(status: QrValidationStatus.failure, errorMessage: f.message)),
    (r) => emit(state.copyWith(status: QrValidationStatus.completed, result: r)),
  );
}
```

**Tarefa 4.4 — Novo widget `ConsultationValueSheet`**  
Arquivo: `lib/features/admin/presentation/widgets/consultation_value_sheet.dart`

```dart
// Campos:
// - TextEditingController para valor (moeda)
// - Preview calculado em tempo real com DiscountService
// - Botão "Confirmar Desconto"
// - onConfirm: (double originalValue) callback
```

Preview em tempo real:
```
Valor da consulta:   R$ 150,00
Desconto (15%):    - R$ 22,50
Valor final:         R$ 127,50
```

**Tarefa 4.5 — Orquestrar o fluxo no sheet do admin**  
Após resultado `approved`:
1. Exibir `QrValidationResultCard` com nome, nível, % desconto
2. Botão "Informar Valor da Consulta" → abre `ConsultationValueSheet`
3. `ConsultationValueSheet.onConfirm` → chama `RecordConsultationUseCase`
4. Sucesso → mostra `_ConsultationSuccessSheet` com resumo

**Verificação Phase 4:**
- [ ] Scanner chama o Supabase para validar
- [ ] QR inválido → exibe mensagem de erro real
- [ ] Admin digita R$ 200,00 com desconto 20% → preview mostra R$ 40,00 poupados
- [ ] Confirmar → consulta aparece no banco

---

### Phase 5 — Histórico do Membro

**Tarefa 5.1 — Atualizar query de histórico**  
Arquivo: `lib/features/consultation/data/datasources/consultation_supabase_datasource.dart`

Adicionar `original_value, discount_percentage, discount_amount, final_value` ao `.select()`

**Tarefa 5.2 — Atualizar `ConsultationHistoryItem`**  
Arquivo: `lib/features/home/presentation/widgets/consultation_history_item.dart`

Exibir:
- Linha principal: título + data
- Sub-linha (se houver desconto): "Você economizou R$ 22,50"

**Tarefa 5.3 — Totalizar economia na CartãoPage**  
Na seção "Histórico de uso" da `card_page.dart`, adicionar subtítulo com total economizado:
```
Histórico de uso           Economizou R$ 87,50 ↗
```

**Verificação Phase 5:**
- [ ] Histórico exibe dados reais (não mock)
- [ ] Itens com desconto mostram valor economizado
- [ ] Total acumulado correto

---

## 4. ORDEM DE EXECUÇÃO RECOMENDADA

```
Phase 0 (Supabase) → Phase 1 (Domain) → Phase 2 (Data) 
    → Phase 3 (DI + Card) → Phase 4 (Admin Scanner) → Phase 5 (Histórico)
```

Cada phase é independente o suficiente para ser executada em uma sessão separada.  
A Phase 0 é pré-requisito técnico de todas as outras.

---

## 5. ANTI-PATTERNS A EVITAR

- ❌ Não criar `decision: approved` localmente — a decisão sempre vem do Supabase
- ❌ Não usar `DiscountService.getDefaultDiscount()` na UI — usar o valor retornado pelo RPC (fonte de verdade é o banco)
- ❌ Não hardcodar o secret do `QrTokenService` — usar `AppConfig`
- ❌ Não chamar `validate_dependent_qr` para QRs de carteirinha (UUID) — usar `validate_member_qr`
- ❌ Não exibir `_memberCode` nem `_memberName` hardcoded — sempre do `ProfileBloc`

---

## 6. CHECKLIST FINAL DE SHIP

- [ ] Phase 0: migration aplicada em staging e prod
- [ ] Phase 0: RPC testada no Supabase Studio
- [ ] Phase 3: QR real exibido com userId do usuário logado
- [ ] Phase 4: Scanner valida via Supabase (não local)
- [ ] Phase 4: Valor da consulta → desconto calculado corretamente
- [ ] Phase 4: Consulta gravada na tabela com todos os campos
- [ ] Phase 5: Histórico exibe dados reais
- [ ] flutter analyze sem erros
- [ ] flutter test sem falhas
