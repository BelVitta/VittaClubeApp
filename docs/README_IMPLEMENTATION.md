# Vita Clube - Guia de Implementação

## Visão Geral

Este documento lista todas as implementações e documentações disponíveis no projeto Vita Clube.

## Documentações Disponíveis

### 1. Home Page Implementation
**Arquivo:** `HOME_IMPLEMENTATION.md`

Implementação completa da tela inicial (HomePage) com:
- Header com saudação e notificações
- Banner de plano
- Ações rápidas (Planos, Pagar, Benefícios)
- Histórico de consultas
- Bottom navigation

**Figma:** node-id=20-196

---

### 2. Sistema de Badges e Níveis
**Arquivo:** `BADGES_IMPLEMENTATION.md`
**Quick Start:** `QUICK_START_BADGES.md`

Sistema completo de níveis de plano:
- 5 níveis: None, Bronze, Silver, Gold, Diamond
- Cores específicas por nível
- Barra de progresso dinâmica
- Histórico de consultas
- Entity models

**Figma:** node-id=34-1354

**Como usar:**
```dart
final PlanLevel _currentPlanLevel = PlanLevel.bronze;
final double _planProgress = 0.3;
```

---

### 3. Estados de Erro e Sem Conexão
**Arquivo:** `ERROR_STATES_IMPLEMENTATION.md`
**Quick Start:** `QUICK_START_ERROR_STATES.md`

Sistema completo de estados de erro:
- Widget genérico reutilizável
- Página de sem conexão
- Helper de conectividade
- 9 estados pré-configurados

**Figma:** node-id=34-2986

**Como usar:**
```dart
// Exibir erro de conexão
ConnectivityHelper.showNoConnectionPage(context);

// Usar estado pré-configurado
ErrorStatesExamples.serverError(onRetry: () {});
```

---

### 4. Planos de Assinatura
**Arquivo:** `PLANS_IMPLEMENTATION.md`
**Quick Start:** `QUICK_START_PLANS.md`

Tela completa de seleção de planos:
- Carrossel horizontal com cards de planos
- 3 tipos: Mensal, Semestral, Anual
- Seleção via radio buttons
- Lista de benefícios com checkmarks
- Badges de desconto

**Figma:** node-id=51-1010

**Como usar:**
```dart
// Navegar para planos
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => PlansPage()),
);

// Tipos disponíveis
SubscriptionType.monthly     // R$ 34,99
SubscriptionType.semiannual  // R$ 29,99 (30% Off)
SubscriptionType.annual      // R$ 29,99
```

---

## Estrutura do Projeto

```
lib/
├── core/
│   ├── di/                          # Injeção de dependências
│   ├── error/                       # Failures e Exceptions
│   ├── theme/                       # Design system (AppTheme)
│   └── utils/                       # Validators, helpers
│       └── connectivity_helper.dart # Helper de conectividade
│
├── features/
│   ├── auth/                        # Autenticação
│   ├── error/                       # Estados de erro
│   │   └── presentation/pages/
│   │       └── no_connection_page.dart
│   ├── home/                        # Tela inicial
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       ├── consultation_entity.dart
│   │   │       ├── plan_level.dart
│   │   │       ├── plan_status_entity.dart
│   │   │       └── quick_action_entity.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── home_page.dart
│   │       └── widgets/
│   │           ├── consultation_history_item.dart
│   │           ├── empty_consultation_state.dart
│   │           ├── plan_banner.dart
│   │           └── quick_action_card.dart
│   ├── onboarding/                  # Onboarding
│   ├── plans/                       # Planos de assinatura
│   │   ├── domain/entities/
│   │   │   ├── subscription_type.dart
│   │   │   └── plan_entity.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── plans_page.dart
│   │       └── widgets/
│   │           ├── plan_card.dart
│   │           ├── plan_selection_item.dart
│   │           └── plan_benefit_item.dart
│   └── splash/                      # Splash screen
│
└── shared/
    └── widgets/
        ├── error_states/
        │   ├── error_state_widget.dart
        │   └── error_states_examples.dart
        ├── app_bottom_navigation.dart
        ├── primary_button.dart
        └── secondary_button.dart
```

## Fluxo de Navegação

```
SplashPage
    ↓
OnboardingPage
    ↓
LoginPage → RegisterPage
    ↓       ↓
    HomePage (Bronze/Silver/Gold/Diamond)
        ↓
        ├→ PlansPage (Seleção de Planos)
        ├→ PaymentPage (em desenvolvimento)
        └→ BenefitsPage (em desenvolvimento)

Em caso de erro:
    ↓
NoConnectionPage (se sem internet)
ErrorStateWidget (outros erros)
```

## Design System

### Cores Principais
```dart
Primary:        #2C4156  (AppTheme.primaryColor)
Secondary:      #6D7F95  (AppTheme.secondaryText)
Primary Text:   #031535  (AppTheme.primaryText)
Border:         #EBEEF2
Background:     #FFFFFF
```

### Fontes
```dart
Títulos:  Outfit (Medium, Bold)
Body:     Outfit (Regular)
Botões:   Plus Jakarta Sans (SemiBold)
```

### Componentes
```dart
Border Radius:    16px (cards)
Button Radius:    24px
Padding Padrão:   16px
Gap entre cards:  6px, 12px
```

## Como Começar

### 1. Configuração Inicial
```bash
flutter pub get
flutter run
```

### 2. Testar Estados Diferentes

**Home com Bronze:**
```dart
// Em home_page.dart
final PlanLevel _currentPlanLevel = PlanLevel.bronze;
final List<ConsultationEntity> _consultations = [...];
```

**Home sem plano:**
```dart
final PlanLevel _currentPlanLevel = PlanLevel.none;
final List<ConsultationEntity> _consultations = [];
```

**Erro de conexão:**
```dart
ConnectivityHelper.showNoConnectionPage(context);
```

### 3. Integrar com Backend

1. Criar data sources em `data/datasources/`
2. Criar repositories em `data/repositories/`
3. Criar use cases em `domain/usecases/`
4. Criar BLoC em `presentation/bloc/`
5. Registrar no DI: `core/di/injection_container.dart`

## Dependências Principais

```yaml
dependencies:
  flutter_bloc: ^8.1.6      # State management
  equatable: ^2.0.5         # Value comparison
  dartz: ^0.10.1            # Functional programming
  get_it: ^7.6.7            # Dependency injection
  google_fonts: ^6.2.1      # Fontes
  intl: ^0.19.0             # Formatação de datas
```

## Próximas Implementações

### Funcionalidades Pendentes
- [x] Tela de Planos (Completa)
- [ ] Tela de Pagamento
- [ ] Tela de Benefícios
- [ ] Tela de Perfil
- [ ] Detalhes da Consulta
- [ ] Notificações
- [ ] Filtros e Busca
- [ ] Página de Sucesso da Assinatura

### Melhorias Técnicas
- [ ] Adicionar connectivity_plus
- [ ] Implementar cache local
- [ ] Analytics e Crashlytics
- [ ] Testes unitários
- [ ] Testes de widget
- [ ] CI/CD pipeline

### Assets
- [ ] Baixar badges de Prata, Ouro, Diamante
- [ ] Salvar ilustrações localmente
- [ ] Otimizar imagens

## Testing

### Rodar Testes
```bash
flutter test                    # Todos os testes
flutter test test/unit/         # Unitários
flutter test test/widget/       # Widget tests
```

### Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Troubleshooting

### Imagens não carregam
- URLs do Figma expiram em 7 dias
- Salve localmente em `assets/images/`
- Implemente fallback com `errorBuilder`

### Estado não atualiza
- Verifique se está usando `setState()`
- Verifique eventos do BLoC
- Verifique imports corretos

### Layout quebrado
- Verifique SafeArea
- Verifique constraints do Container
- Use Flutter Inspector

## Recursos Úteis

### Documentação
- [Flutter Docs](https://docs.flutter.dev/)
- [BLoC Library](https://bloclibrary.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### Ferramentas
- Flutter DevTools
- VS Code Flutter Extension
- Figma Dev Mode

## Contribuindo

1. Crie uma branch: `git checkout -b feature/nova-feature`
2. Commit suas mudanças: `git commit -m 'Add nova feature'`
3. Push: `git push origin feature/nova-feature`
4. Abra um Pull Request

## Convenções de Código

- Seguir Clean Architecture
- Usar BLoC para state management
- Nomear arquivos em snake_case
- Nomear classes em PascalCase
- Documentar código complexo
- Adicionar testes

## Contato

Para dúvidas sobre implementação, consulte as documentações específicas ou abra uma issue.

---

**Última atualização:** 06/02/2026
**Versão:** 1.0.0
