# Badge System Implementation - Vita Clube

## Implementado do Figma Design
Design Source: https://www.figma.com/design/nNc2umOfTeoX0itneDki1b/Vitta-Clube-App?node-id=34-1354

## Visão Geral

Sistema de badges com 4 níveis de plano implementado seguindo Clean Architecture:
- **Sem Plano** (None)
- **Bronze** 🥉
- **Prata** 🥈 (em desenvolvimento)
- **Ouro** 🥇 (em desenvolvimento)
- **Diamante** 💎 (em desenvolvimento)

## Arquivos Criados

### Domain Layer

#### 1. `lib/features/home/domain/entities/plan_level.dart`
Enum que define os níveis de plano com suas características:
```dart
enum PlanLevel {
  none, bronze, silver, gold, diamond
}
```

**Propriedades por nível:**
- `displayName`: Nome exibido ("Sem plano", "Bronze", "Prata", etc.)
- `nextLevel`: Próximo nível na progressão
- `progressColor`: Cor da barra de progresso
- `progressBackgroundColor`: Cor de fundo da barra

**Cores de Progresso:**
- Sem Plano: Cinza claro (#F6F6F6)
- Bronze: Laranja cobre (#C25C3C) sobre fundo azul claro (#CFDAED)
- Prata: Prata (#C0C0C0) sobre fundo cinza (#E8E8E8)
- Ouro: Dourado (#FFD700) sobre fundo amarelo claro (#FFF4D1)
- Diamante: Azul claro (#B9F2FF) sobre fundo azul muito claro (#E3F8FF)

**Métodos:**
- `getBadgeUrl()`: Retorna URL do badge correspondente ao nível
- `getStatusText()`: Retorna "Assine Vita Clube" para none, "Ativo" para outros

#### 2. `lib/features/home/domain/entities/consultation_entity.dart`
Entidade que representa uma consulta médica no histórico:
```dart
class ConsultationEntity {
  final String id;
  final String title;          // Ex: "Consulta Clínica Geral"
  final String subtitle;        // Ex: "Retorno de acompanhamento"
  final DateTime date;
  final String badgeIconUrl;
}
```

### Presentation Layer

#### 3. `lib/features/home/presentation/widgets/consultation_history_item.dart`
Widget que representa um item individual no histórico de consultas.

**Props:**
- `title`: Título da consulta
- `subtitle`: Subtítulo/descrição
- `date`: Data da consulta (formatada como dd/MM/yyyy)
- `badgeIconUrl`: URL do ícone do badge
- `onTap`: Callback opcional para navegação

**Layout:**
```
┌─────────────────────────────────────────┐
│ [Badge] Título da Consulta    05/11/2025│
│         Subtítulo                        │
└─────────────────────────────────────────┘
```

**Características:**
- Badge circular com fundo azul translúcido
- Texto de 10px
- Data alinhada à direita com opacidade 40%
- Border radius 16px
- Padding 12px

### Atualizações em Componentes Existentes

#### 4. Atualização: `plan_banner.dart`
Refatorado para usar `PlanLevel` enum.

**Antes:**
```dart
PlanBanner(
  currentPlan: 'Bronze',
  nextPlan: 'Prata',
  progress: 0.3,
  badgeUrl: 'https://...',
)
```

**Depois:**
```dart
PlanBanner(
  planLevel: PlanLevel.bronze,
  progress: 0.3,
)
```

**Melhorias:**
- Sistema de cores automático baseado no nível
- Badge com fundo poligonal
- Progresso com cores específicas por nível
- Texto de status dinâmico

#### 5. Atualização: `home_page.dart`
Suporta dois estados:

**Estado 1: Sem Consultas**
- Exibe ilustração de estado vazio
- Mensagem "Sem Consultas"
- Texto explicativo

**Estado 2: Com Consultas**
- Lista de itens de consulta
- Scroll vertical
- Spacing de 6px entre itens

**Configurações de Teste:**
```dart
// Para testar estado vazio:
final List<ConsultationEntity> _consultations = [];

// Para testar com Bronze:
final PlanLevel _currentPlanLevel = PlanLevel.bronze;
final double _planProgress = 0.3; // 30% progresso

// Para testar outros níveis:
final PlanLevel _currentPlanLevel = PlanLevel.silver;
// ou PlanLevel.gold, PlanLevel.diamond
```

## Dependência Adicionada

```yaml
dependencies:
  intl: ^0.19.0  # Para formatação de datas
```

## Como Usar

### 1. Configurar Nível do Plano

No arquivo `home_page.dart`, altere:
```dart
final PlanLevel _currentPlanLevel = PlanLevel.bronze; // ou silver, gold, diamond
final double _planProgress = 0.3; // 0.0 a 1.0
```

### 2. Adicionar/Remover Consultas

```dart
// Lista vazia = estado vazio
final List<ConsultationEntity> _consultations = [];

// Com consultas
final List<ConsultationEntity> _consultations = [
  ConsultationEntity(
    id: '1',
    title: 'Consulta Clínica Geral',
    subtitle: 'Retorno de acompanhamento',
    date: DateTime(2025, 11, 5),
    badgeIconUrl: _consultationBadgeUrl,
  ),
  // ... mais consultas
];
```

### 3. Testar Diferentes Estados

```dart
// Sem plano, sem consultas
PlanLevel.none + consultations = []

// Bronze, com consultas
PlanLevel.bronze + consultations = [...]

// Prata, com consultas
PlanLevel.silver + consultations = [...]
```

## Assets do Figma

### Badge URLs por Nível:
- **None/Sem Plano**: `13dd3e7a-288a-4089-9ceb-fc541fc4d9eb`
- **Bronze**: `bb529a16-33e4-4390-a25b-4253062186a7`
- **Prata**: A ser adicionado
- **Ouro**: A ser adicionado
- **Diamante**: A ser adicionado

### Outros Assets:
- **Badge Polygon Background**: `75226959-daf9-4718-a865-b723dc866f42`
- **Consultation Icon**: `65b8158d-9f48-4049-a14a-deef24a5d939`

## Próximos Passos

### Backend Integration (TODO)
1. Criar repository para buscar dados reais do plano
2. Criar repository para buscar histórico de consultas
3. Criar use cases:
   - `GetUserPlanUseCase`
   - `GetConsultationHistoryUseCase`
4. Criar BLoC para gerenciar estado:
   - `HomeBlocEvent`: FetchPlanStatus, FetchConsultations
   - `HomeBlocState`: Loading, Loaded, Error

### Assets Production (TODO)
1. Baixar badges de Prata, Ouro e Diamante do Figma
2. Salvar em `assets/images/badges/`
3. Atualizar `plan_level.dart` com paths locais

### Features Adicionais
1. Navegação para detalhes da consulta
2. Filtro de consultas por data/tipo
3. Paginação do histórico
4. Animação de transição entre níveis
5. Notificação de upgrade de plano

## Guia de Estilo

### Cores por Nível
```dart
Bronze:  #C25C3C (progress) / #CFDAED (background)
Prata:   #C0C0C0 (progress) / #E8E8E8 (background)
Ouro:    #FFD700 (progress) / #FFF4D1 (background)
Diamante:#B9F2FF (progress) / #E3F8FF (background)
```

### Tipografia
- **Título do plano**: Outfit Medium, 20px
- **Subtítulo (próximo nível)**: Outfit Medium, 10px, 40% opacity
- **Status**: Outfit Medium, 10px, 40% opacity
- **Título consulta**: Outfit Medium, 10px
- **Subtítulo consulta**: Outfit Regular, 10px, 40% opacity
- **Data**: Outfit Medium, 10px, 40% opacity

### Espaçamentos
- Card padding: 12px (consultas), 16px (plano)
- Gap entre consultas: 6px
- Gap entre seções: 12px
- Border radius: 16px (padrão)
- Badge size: 25x25px
- Badge icon padding: 5.882px

## Exemplo de Integração Completa

```dart
// 1. Criar BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetUserPlanUseCase getUserPlan;
  final GetConsultationHistoryUseCase getConsultations;

  HomeBloc({
    required this.getUserPlan,
    required this.getConsultations,
  }) : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    final planResult = await getUserPlan();
    final consultationsResult = await getConsultations();

    // Handle results...
    emit(HomeLoaded(
      planLevel: planLevel,
      progress: progress,
      consultations: consultations,
    ));
  }
}

// 2. Usar no HomePage
BlocBuilder<HomeBloc, HomeState>(
  builder: (context, state) {
    if (state is HomeLoaded) {
      return PlanBanner(
        planLevel: state.planLevel,
        progress: state.progress,
      );
    }
    // Handle loading/error states
  },
)
```

## Testing

### Unit Tests
```dart
test('PlanLevel.bronze should have correct colors', () {
  expect(PlanLevel.bronze.progressColor, Color(0xFFC25C3C));
  expect(PlanLevel.bronze.displayName, 'Bronze');
});

test('ConsultationEntity should format date correctly', () {
  final entity = ConsultationEntity(
    date: DateTime(2025, 11, 5),
    // ...
  );
  // Test formatting
});
```

### Widget Tests
```dart
testWidgets('PlanBanner shows correct plan name', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PlanBanner(
        planLevel: PlanLevel.bronze,
        progress: 0.3,
      ),
    ),
  );

  expect(find.text('Bronze'), findsOneWidget);
  expect(find.text('/ Prata'), findsOneWidget);
});
```
