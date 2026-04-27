## Implementado do Figma Design
Design Source: https://www.figma.com/design/nNc2umOfTeoX0itneDki1b/Vitta-Clube-App?node-id=51-1010

## Visão Geral

Tela completa de seleção de planos de assinatura com carrossel horizontal e seleção via radio buttons.

## Arquivos Criados

### Domain Layer

#### 1. `lib/features/plans/domain/entities/subscription_type.dart`
Enum que define os tipos de assinatura disponíveis.

**Tipos:**
```dart
enum SubscriptionType {
  monthly,      // R$ 34,99
  semiannual,   // R$ 29,99 (30% Off)
  annual,       // R$ 29,99
}
```

**Propriedades:**
- `displayName`: Nome exibido ("Mensal", "Semestral", "Anual")
- `price`: Preço do plano
- `discount`: Texto de desconto (nullable)
- `formattedPrice`: Preço formatado "R$ XX,XX"
- `hasDiscount`: Verifica se tem desconto

#### 2. `lib/features/plans/domain/entities/plan_entity.dart`
Entidades para planos e benefícios.

**PlanBenefit:**
```dart
class PlanBenefit {
  final String title;       // "Lorem Ipsum"
  final String description; // Descrição do benefício
}
```

**PlanEntity:**
```dart
class PlanEntity {
  final SubscriptionType type;
  final List<PlanBenefit> benefits;
}
```

### Presentation Layer

#### 3. `lib/features/plans/presentation/widgets/plan_benefit_item.dart`
Widget que exibe um benefício com checkmark.

**Props:**
```dart
PlanBenefitItem({
  required String title,
  required String description,
  String? checkIconUrl,
})
```

**Layout:**
```
✓ Lorem Ipsum
  Lorem ipsum dolor sit amet...
```

**Características:**
- Checkmark de 16x16px
- Título: Outfit Medium, 10px
- Descrição: Outfit Regular, 10px, cor secundária
- Gap de 8px horizontal

#### 4. `lib/features/plans/presentation/widgets/plan_card.dart`
Card de plano para o carrossel horizontal.

**Props:**
```dart
PlanCard({
  required PlanEntity plan,
  String? checkIconUrl,
})
```

**Características:**
- Width: 314px
- Padding: 16px
- Border: 1px, #7C96C4
- Border radius: 16px
- Margin right: 12px
- Lista de até 6 benefícios

**Layout:**
```
┌──────────────────────┐
│ Mensal               │
│ ✓ Benefício 1        │
│ ✓ Benefício 2        │
│ ✓ Benefício 3        │
│ ✓ Benefício 4        │
│ ✓ Benefício 5        │
│ ✓ Benefício 6        │
└──────────────────────┘
```

#### 5. `lib/features/plans/presentation/widgets/plan_selection_item.dart`
Item de seleção com radio button.

**Props:**
```dart
PlanSelectionItem({
  required SubscriptionType type,
  required bool isSelected,
  required VoidCallback onTap,
})
```

**Estados:**

**Selecionado:**
```
┌─────────────────────────────┐
│ ◉ Mensal    R$ 34,99       │
└─────────────────────────────┘
Border: #2C4156
Radio: Filled com check
```

**Não selecionado:**
```
┌─────────────────────────────┐
│ ○ Semestral [30% Off] R$29,99│
└─────────────────────────────┘
Border: #EBEEF2
Radio: Empty
```

**Características:**
- Padding: 12px
- Border radius: 16px
- Badge de desconto: bg #2C4156, texto branco
- Transição de estado ao clicar

#### 6. `lib/features/plans/presentation/pages/plans_page.dart`
Página principal de seleção de planos.

**Estrutura:**
```
┌─────────────────────────────┐
│ ← [Back Button]            │
│                             │
│ Planos                      │
│ Conheça nossos planos...    │
│                             │
│ [Carrossel Horizontal]      │
│ ┌───┐ ┌───┐ ┌───┐         │
│ │ M │ │ S │ │ A │         │
│ └───┘ └───┘ └───┘         │
│                             │
│ ◉ Mensal        R$ 34,99    │
│ ○ Semestral     R$ 29,99    │
│ ○ Anual         R$ 29,99    │
│                             │
│                             │
│     [Continuar Button]      │
└─────────────────────────────┘
```

**Features:**
- Background gradient circular no topo
- Botão voltar no header
- Título e descrição
- PageView horizontal para carrossel de planos
- 3 opções de seleção com radio buttons
- Botão "Continuar" fixo na parte inferior

## Como Usar

### 1. Navegação Básica

```dart
// Navegar para PlansPage
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => PlansPage(),
  ),
);

// Com callback de retorno
final selectedPlan = await Navigator.push<SubscriptionType>(
  context,
  MaterialPageRoute(
    builder: (_) => PlansPage(),
  ),
);

if (selectedPlan != null) {
  print('Plano selecionado: ${selectedPlan.displayName}');
}
```

### 2. Integrar com HomePage

```dart
// Em home_page.dart
QuickActionCard(
  title: 'Planos',
  iconUrl: _planosIconUrl,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlansPage(),
      ),
    );
  },
),
```

### 3. Modificar Dados dos Planos

```dart
// Em _PlansPageState
List<PlanEntity> _createMockPlans() {
  return [
    PlanEntity(
      type: SubscriptionType.monthly,
      benefits: [
        PlanBenefit(
          title: 'Consultas Ilimitadas',
          description: 'Acesso a consultas médicas sem limite',
        ),
        PlanBenefit(
          title: 'Desconto em Exames',
          description: 'Até 50% de desconto em exames laboratoriais',
        ),
        // ... mais benefícios
      ],
    ),
    // ... outros planos
  ];
}
```

### 4. Customizar Preços

```dart
// Em subscription_type.dart
enum SubscriptionType {
  monthly('Mensal', 49.90, null),
  semiannual('Semestral', 39.90, '20% Off'),
  annual('Anual', 29.90, '40% Off');
}
```

## Assets do Figma

**Check Icon:**
- URL: `e62e011b-b8ab-44e3-8e2e-cd2155b11db7`
- Size: 16x16px
- Usado em cada benefício

**Arrow Icon:**
- URL: `9bf3a85e-23ef-42df-840f-7fb9ac041ada`
- Size: 19.5x19.5px
- Botão voltar

## Design Tokens

### Cores
```dart
Primary:       #2C4156  (AppTheme.primaryColor)
Secondary:     #6D7F95  (Texto secundário)
Border Normal: #EBEEF2  (Items não selecionados)
Border Active: #7C96C4  (Cards) / #2C4156 (Selected)
Discount BG:   #2C4156  (Badge de desconto)
```

### Tipografia
```dart
Página Título:     Outfit Bold, 24px, spacing 0.12px
Descrição:         Outfit Regular, 14px, spacing 0.07px
Card Título:       Outfit Medium, 16px
Benefício Título:  Outfit Medium, 10px
Benefício Desc:    Outfit Regular, 10px
Seleção Título:    Outfit Medium, 13px
Preço:             Outfit Regular, 16px
Badge:             Outfit Regular, 10px
```

### Espaçamentos
```dart
Card padding:        16px
Card gap:            6px
Benefit padding V:   8px
Benefit gap H:       8px
Selection items gap: 6px
Bottom button:       16px from bottom
Content padding H:   16px
```

## Comportamento do Carrossel

### PageView Horizontal
```dart
PageController _pageController = PageController();

PageView.builder(
  controller: _pageController,
  itemCount: _plans.length,
  itemBuilder: (context, index) {
    return PlanCard(plan: _plans[index]);
  },
)
```

**Características:**
- Scroll horizontal
- Snap automático nos cards
- Física padrão do iOS/Android
- Cards com width fixo (314px)

### Sincronizar com Seleção

Para sincronizar o carrossel com a seleção:

```dart
// Quando seleciona um plano
void _selectPlan(SubscriptionType type) {
  setState(() {
    _selectedPlan = type;
  });

  // Animar para o card correspondente
  final index = _plans.indexWhere((p) => p.type == type);
  if (index != -1) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
```

## Exemplo: Processar Assinatura

```dart
void _handleContinue() async {
  // Mostrar loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(child: CircularProgressIndicator()),
  );

  try {
    // Processar assinatura
    final success = await subscriptionService.subscribe(
      type: _selectedPlan,
      userId: currentUser.id,
    );

    Navigator.pop(context); // Fechar loading

    if (success) {
      // Navegar para confirmação
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionSuccessPage(),
        ),
      );
    }
  } catch (e) {
    Navigator.pop(context); // Fechar loading

    // Mostrar erro
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Erro'),
        content: Text('Não foi possível processar a assinatura'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

## Integração com Backend

### 1. Criar Repository

```dart
// lib/features/plans/domain/repositories/plans_repository.dart
abstract class PlansRepository {
  Future<Either<Failure, List<PlanEntity>>> getPlans();
  Future<Either<Failure, void>> subscribeToPlan(SubscriptionType type);
}
```

### 2. Criar Use Case

```dart
// lib/features/plans/domain/usecases/get_plans_usecase.dart
class GetPlansUseCase {
  final PlansRepository repository;

  GetPlansUseCase(this.repository);

  Future<Either<Failure, List<PlanEntity>>> call() {
    return repository.getPlans();
  }
}
```

### 3. Criar BLoC

```dart
// Events
abstract class PlansEvent {}
class LoadPlans extends PlansEvent {}
class SelectPlan extends PlansEvent {
  final SubscriptionType type;
  SelectPlan(this.type);
}
class ConfirmSubscription extends PlansEvent {}

// States
abstract class PlansState {}
class PlansInitial extends PlansState {}
class PlansLoading extends PlansState {}
class PlansLoaded extends PlansState {
  final List<PlanEntity> plans;
  final SubscriptionType selectedPlan;
  PlansLoaded(this.plans, this.selectedPlan);
}
class PlansError extends PlansState {
  final String message;
  PlansError(this.message);
}
class SubscriptionSuccess extends PlansState {}

// BLoC
class PlansBloc extends Bloc<PlansEvent, PlansState> {
  final GetPlansUseCase getPlans;
  final SubscribeToPlanUseCase subscribeToPlan;

  PlansBloc({
    required this.getPlans,
    required this.subscribeToPlan,
  }) : super(PlansInitial()) {
    on<LoadPlans>(_onLoadPlans);
    on<SelectPlan>(_onSelectPlan);
    on<ConfirmSubscription>(_onConfirmSubscription);
  }

  // Implementation...
}
```

### 4. Atualizar PlansPage

```dart
class PlansPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PlansBloc>()..add(LoadPlans()),
      child: PlansView(),
    );
  }
}

class PlansView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlansBloc, PlansState>(
      listener: (context, state) {
        if (state is SubscriptionSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SubscriptionSuccessPage(),
            ),
          );
        }
        if (state is PlansError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is PlansLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (state is PlansLoaded) {
          return _buildContent(state.plans, state.selectedPlan);
        }

        return Container();
      },
    );
  }
}
```

## Testing

### Unit Tests

```dart
test('SubscriptionType should format price correctly', () {
  expect(
    SubscriptionType.monthly.formattedPrice,
    'R\$ 34,99',
  );
});

test('PlanEntity should have correct type and benefits', () {
  final plan = PlanEntity(
    type: SubscriptionType.monthly,
    benefits: [
      PlanBenefit(title: 'Test', description: 'Desc'),
    ],
  );

  expect(plan.type, SubscriptionType.monthly);
  expect(plan.benefits.length, 1);
});
```

### Widget Tests

```dart
testWidgets('PlansPage shows all subscription options', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: PlansPage()),
  );

  expect(find.text('Planos'), findsOneWidget);
  expect(find.text('Mensal'), findsOneWidget);
  expect(find.text('Semestral'), findsOneWidget);
  expect(find.text('Anual'), findsOneWidget);
  expect(find.text('Continuar'), findsOneWidget);
});

testWidgets('Selecting a plan updates the radio button', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: PlansPage()),
  );

  // Tap on Semestral
  await tester.tap(find.text('Semestral'));
  await tester.pumpAndSettle();

  // Verify selection changed
  // (Check for visual indicators like border color)
});
```

## Customizações Futuras

### 1. Adicionar Animações
```dart
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  decoration: BoxDecoration(
    border: Border.all(
      color: isSelected ? primaryColor : borderColor,
    ),
  ),
)
```

### 2. Indicadores de Página
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(
    _plans.length,
    (index) => Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: currentPage == index ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: currentPage == index
            ? primaryColor
            : primaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  ),
)
```

### 3. Comparação de Planos
```dart
// Adicionar botão "Comparar Planos"
TextButton(
  onPressed: () => showComparisonDialog(),
  child: Text('Comparar Planos'),
)
```

### 4. Trial Gratuito
```dart
if (plan.hasFreeTrial) {
  Container(
    child: Text('7 dias grátis'),
  )
}
```

## Troubleshooting

### Carrossel não scroll
- Verificar `physics` do PageView
- Verificar height do container pai

### Radio button não atualiza
- Verificar `setState()` no onTap
- Verificar comparação de igualdade

### Preço não formata corretamente
- Verificar locale do app
- Usar `NumberFormat` do pacote `intl`

## Próximos Passos

1. Implementar backend integration
2. Adicionar analytics
3. Implementar payment gateway
4. Adicionar página de sucesso
5. Adicionar FAQ dos planos
6. Implementar cupons de desconto

## Recursos Adicionais

- [Flutter PageView](https://api.flutter.dev/flutter/widgets/PageView-class.html)
- [Material Radio Button](https://material.io/components/radio-buttons)
- [Subscription Best Practices](https://stripe.com/docs/billing/subscriptions/overview)
