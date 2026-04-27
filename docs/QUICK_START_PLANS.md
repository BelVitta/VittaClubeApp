# Quick Start - Planos de Assinatura

## Uso Básico

### 1. Navegar para Tela de Planos

```dart
import 'package:vita_clube/features/plans/presentation/pages/plans_page.dart';

// Navegação simples
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => PlansPage()),
);

// Com retorno
final selectedPlan = await Navigator.push<SubscriptionType>(
  context,
  MaterialPageRoute(builder: (_) => PlansPage()),
);

print('Selecionado: ${selectedPlan?.displayName}');
```

### 2. Integrar com Home

```dart
// Em home_page.dart
QuickActionCard(
  title: 'Planos',
  iconUrl: _planosIconUrl,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PlansPage()),
  ),
)
```

## Estrutura de Planos

### Tipos Disponíveis

```dart
SubscriptionType.monthly     // R$ 34,99
SubscriptionType.semiannual  // R$ 29,99 (30% Off)
SubscriptionType.annual      // R$ 29,99
```

### Modificar Preços

```dart
// Em subscription_type.dart
enum SubscriptionType {
  monthly('Mensal', 49.90, null),
  semiannual('Semestral', 39.90, '20% Off'),
  annual('Anual', 29.90, '40% Off');
}
```

### Modificar Benefícios

```dart
// Em plans_page.dart (_createMockPlans)
List<PlanEntity> _createMockPlans() {
  final benefits = [
    PlanBenefit(
      title: 'Consultas Ilimitadas',
      description: 'Acesso a consultas médicas sem limite',
    ),
    PlanBenefit(
      title: 'Desconto em Exames',
      description: 'Até 50% de desconto em exames',
    ),
    // ... até 6 benefícios
  ];

  return [
    PlanEntity(type: SubscriptionType.monthly, benefits: benefits),
    PlanEntity(type: SubscriptionType.semiannual, benefits: benefits),
    PlanEntity(type: SubscriptionType.annual, benefits: benefits),
  ];
}
```

## Componentes

### PlanCard (Carrossel)
```dart
PlanCard(
  plan: planEntity,
  checkIconUrl: 'https://...',
)
```

### PlanSelectionItem (Radio Button)
```dart
PlanSelectionItem(
  type: SubscriptionType.monthly,
  isSelected: true,
  onTap: () => _selectPlan(SubscriptionType.monthly),
)
```

### PlanBenefitItem (Checkmark)
```dart
PlanBenefitItem(
  title: 'Título',
  description: 'Descrição do benefício',
  checkIconUrl: 'https://...',
)
```

## Processar Assinatura

```dart
void _handleContinue() {
  final selectedPlan = _selectedPlan;

  // Processar assinatura
  subscriptionService.subscribe(
    type: selectedPlan,
    userId: currentUser.id,
  );

  // Navegar para confirmação
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => SubscriptionSuccessPage(),
    ),
  );
}
```

## Estados da Página

### Carrossel Horizontal
- 3 cards deslizáveis
- Width fixo de 314px por card
- Scroll automático com snap

### Seleção de Plano
- Radio buttons customizados
- Border muda quando selecionado
- Badge de desconto no Semestral

### Botão Continuar
- Fixo na parte inferior
- Sempre visível
- Retorna plano selecionado

## Testar

```bash
flutter pub get
flutter run
```

Navegue: Home → Planos

## Estrutura de Arquivos

```
lib/features/plans/
├── domain/entities/
│   ├── subscription_type.dart   ← Tipos de plano
│   └── plan_entity.dart         ← Entity do plano
└── presentation/
    ├── pages/
    │   └── plans_page.dart      ← Página principal
    └── widgets/
        ├── plan_card.dart       ← Card do carrossel
        ├── plan_selection_item.dart ← Radio button
        └── plan_benefit_item.dart   ← Item com check
```

## Próximos Passos

1. ✅ Página implementada
2. ✅ Carrossel funcional
3. ✅ Seleção com radio buttons
4. [ ] Integrar com backend
5. [ ] Adicionar analytics
6. [ ] Implementar payment gateway

## Documentação Completa

Consulte: `PLANS_IMPLEMENTATION.md`
