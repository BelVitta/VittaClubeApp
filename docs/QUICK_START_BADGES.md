# Quick Start - Sistema de Badges

## Instalação Rápida

```bash
flutter pub get
flutter run
```

## Como Testar Diferentes Estados

### 1. Testar Plano Bronze com Consultas

No arquivo `lib/features/home/presentation/pages/home_page.dart`:

```dart
final PlanLevel _currentPlanLevel = PlanLevel.bronze;
final double _planProgress = 0.3; // 30%
final List<ConsultationEntity> _consultations = [...]; // Mantém a lista
```

### 2. Testar Sem Plano (Estado Vazio)

```dart
final PlanLevel _currentPlanLevel = PlanLevel.none;
final double _planProgress = 0.0;
final List<ConsultationEntity> _consultations = []; // Lista vazia
```

### 3. Testar Plano Prata

```dart
final PlanLevel _currentPlanLevel = PlanLevel.silver;
final double _planProgress = 0.5; // 50%
final List<ConsultationEntity> _consultations = [...];
```

### 4. Testar Plano Ouro

```dart
final PlanLevel _currentPlanLevel = PlanLevel.gold;
final double _planProgress = 0.7; // 70%
final List<ConsultationEntity> _consultations = [...];
```

### 5. Testar Plano Diamante

```dart
final PlanLevel _currentPlanLevel = PlanLevel.diamond;
final double _planProgress = 1.0; // 100%
final List<ConsultationEntity> _consultations = [...];
```

## Estados Disponíveis

| Plano | Display | Próximo | Cor Progresso | Estado |
|-------|---------|---------|---------------|--------|
| None | Sem plano | Bronze | Cinza (#F6F6F6) | ✅ Implementado |
| Bronze | Bronze | Prata | Laranja (#C25C3C) | ✅ Implementado |
| Silver | Prata | Ouro | Prata (#C0C0C0) | ⚠️ Badge pendente |
| Gold | Ouro | Diamante | Dourado (#FFD700) | ⚠️ Badge pendente |
| Diamond | Diamante | Diamante | Azul (#B9F2FF) | ⚠️ Badge pendente |

## Estrutura de Consultas Mock

```dart
final List<ConsultationEntity> _consultations = [
  ConsultationEntity(
    id: '1',
    title: 'Consulta Clínica Geral',
    subtitle: 'Retorno de acompanhamento',
    date: DateTime(2025, 11, 5),
    badgeIconUrl: _consultationBadgeUrl,
  ),
  ConsultationEntity(
    id: '2',
    title: 'Nutrição / Avaliação Alimentar',
    subtitle: 'Ajuste de plano nutricional',
    date: DateTime(2025, 10, 22),
    badgeIconUrl: _consultationBadgeUrl,
  ),
  // Adicione mais conforme necessário
];
```

## Preview dos Estados

### Estado 1: Sem Plano + Sem Consultas
```
┌─────────────────────────────┐
│ Assine Vita Clube           │
│ Sem plano / Bronze          │
│ ▓░░░░░░░░░░░░░░░░░░ (0%)    │
└─────────────────────────────┘

Histórico de consultas
[Ilustração de estado vazio]
Sem Consultas
Sem consultas no momento...
```

### Estado 2: Bronze + Com Consultas
```
┌─────────────────────────────┐
│ Ativo                       │
│ Bronze / Prata          🥉  │
│ ▓▓▓▓▓▓░░░░░░░░░░░░░ (30%)   │
└─────────────────────────────┘

Histórico de consultas
┌─────────────────────────────┐
│ 🏥 Consulta...    05/11/2025│
│    Retorno...               │
└─────────────────────────────┘
┌─────────────────────────────┐
│ 🏥 Nutrição...    22/10/2025│
│    Ajuste...                │
└─────────────────────────────┘
```

## Modificar Cores de Progresso

Edite `lib/features/home/domain/entities/plan_level.dart`:

```dart
enum PlanLevel {
  bronze(
    'Bronze',
    'Prata',
    Color(0xFFC25C3C),      // <- Cor da barra
    Color(0xFFCFDAED),      // <- Cor de fundo
  ),
  // ...
}
```

## Navegação após Login

O fluxo atual:
```
Login → HomePage (Bronze com consultas)
```

Para alterar o estado inicial, modifique `home_page.dart` linhas 24-70.

## Troubleshooting

### Erro: "intl package not found"
```bash
flutter pub get
```

### Imagens não carregam
- Verifique conexão com internet
- URLs do Figma expiram em 7 dias
- Para produção, baixe e salve em `assets/images/`

### Progress bar não aparece
- Verifique se `progress` está entre 0.0 e 1.0
- Progress de 0.0 ainda mostra a barra, só não preenchida

### Cores erradas no badge
- Verifique se está usando `PlanLevel.bronze` (não string)
- Certifique-se de que o enum está importado

## Arquivos Importantes

```
lib/features/home/
├── domain/entities/
│   ├── plan_level.dart           ← Níveis e cores
│   ├── consultation_entity.dart  ← Modelo de consulta
│   └── plan_status_entity.dart
├── presentation/
│   ├── pages/
│   │   └── home_page.dart        ← MODIFICAR AQUI
│   └── widgets/
│       ├── plan_banner.dart      ← Banner do plano
│       └── consultation_history_item.dart
```

## Próximo: Integrar com Backend

1. Criar data source em `lib/features/home/data/datasources/`
2. Criar repository em `lib/features/home/data/repositories/`
3. Criar use cases em `lib/features/home/domain/usecases/`
4. Criar BLoC em `lib/features/home/presentation/bloc/`
5. Atualizar DI em `lib/core/di/injection_container.dart`

## Dúvidas?

Consulte: `BADGES_IMPLEMENTATION.md` para documentação completa.
