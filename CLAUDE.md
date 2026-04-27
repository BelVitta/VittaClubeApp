# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Vita Clube - Sistema de fidelidade em Flutter usando Clean Architecture + BLoC.

## Build & Development Commands

```bash
flutter pub get          # Instalar dependências
flutter test             # Rodar testes
flutter analyze          # Verificar erros de lint
dart format lib/         # Formatar código
```

### Ambientes (entry points)

O app tem três entry points — escolha com `-t`:

```bash
# Dev: dados mock locais, sem Supabase
flutter run -t lib/main_dev.dart

# Staging: projeto Supabase `vita-clube-dev` (dados descartáveis, seed demo)
flutter run -t lib/main_staging.dart

# Produção: projeto Supabase de prod
flutter run -t lib/main_prod.dart
```

Passe `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
para sobrescrever os defaults em `lib/core/config/app_config.dart`.

### Build

```bash
flutter build apk -t lib/main_prod.dart --release   # Android prod
flutter build apk -t lib/main_staging.dart          # Android staging
```

## Arquitetura (Clean Architecture + BLoC)

```
lib/
├── main.dart
├── core/                    # Compartilhado entre features
│   ├── di/                  # Injeção de dependências (get_it)
│   ├── error/               # Failures e Exceptions
│   ├── utils/               # Validators, helpers
│   └── theme/               # Design system
├── features/
│   └── [feature]/
│       ├── data/            # Camada de dados
│       │   ├── datasources/ # Mock ou Remote/Local
│       │   ├── models/      # DTOs (fromJson/toJson)
│       │   └── repositories/# Implementações
│       ├── domain/          # Regras de negócio (Dart puro)
│       │   ├── entities/    # Objetos de negócio
│       │   ├── repositories/# Interfaces (contratos)
│       │   └── usecases/    # Ações do sistema
│       └── presentation/    # UI
│           ├── bloc/        # Estado (events, states, bloc)
│           ├── pages/       # Telas
│           └── widgets/     # Componentes
└── shared/widgets/          # Widgets globais
```

## Regra de Dependência

```
Presentation → Domain ← Data
                ↑
              Core
```

- **Domain nunca importa Data ou Presentation**
- Presentation conhece Domain (Use Cases, Entities)
- Data implementa interfaces do Domain

## Criar Nova Feature

1. Criar pastas: `lib/features/nome/domain/`, `data/`, `presentation/`

2. **Domain** (sem dependências Flutter):
```dart
// entities/nome_entity.dart
class NomeEntity extends Equatable { ... }

// repositories/nome_repository.dart (interface)
abstract class NomeRepository {
  Future<Either<Failure, NomeEntity>> getAlgo();
}

// usecases/get_algo_usecase.dart
class GetAlgoUseCase {
  final NomeRepository repository;
  GetAlgoUseCase(this.repository);
  Future<Either<Failure, NomeEntity>> call() => repository.getAlgo();
}
```

3. **Data**:
```dart
// models/nome_model.dart
class NomeModel extends NomeEntity {
  factory NomeModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}

// repositories/nome_repository_impl.dart
class NomeRepositoryImpl implements NomeRepository { ... }
```

4. **Presentation**:
```dart
// bloc/nome_bloc.dart
class NomeBloc extends Bloc<NomeEvent, NomeState> {
  final GetAlgoUseCase getAlgoUseCase;
  NomeBloc({required this.getAlgoUseCase}) : super(...);
}

// pages/nome_page.dart
class NomePage extends StatelessWidget {
  Widget build(context) => BlocProvider(
    create: (_) => sl<NomeBloc>(),  // get_it
    child: NomeView(),
  );
}
```

5. **Registrar no DI** (`lib/core/di/injection_container.dart`):
```dart
sl.registerFactory(() => NomeBloc(getAlgoUseCase: sl()));
sl.registerLazySingleton(() => GetAlgoUseCase(sl()));
sl.registerLazySingleton<NomeRepository>(() => NomeRepositoryImpl(...));
```

## Convenções de Nomenclatura

| Tipo | Sufixo | Local |
|------|--------|-------|
| Entity | `Entity` | domain/entities/ |
| Model | `Model` | data/models/ |
| Use Case | `UseCase` | domain/usecases/ |
| Repository Interface | `Repository` | domain/repositories/ |
| Repository Impl | `RepositoryImpl` | data/repositories/ |
| Data Source | `DataSource` | data/datasources/ |

## Design System

`lib/core/theme/app_theme.dart`:
- **Cores**: `AppTheme.primaryColor` (#2C4156), `gradientLight`, `gradientDark`
- **Textos**: `AppTheme.headingLarge`, `bodyMedium`, `buttonText`, `labelMedium`
- **Fontes**: Outfit (títulos), Plus Jakarta Sans (body/botões)
- **Input**: `AppTheme.inputDecoration(label: 'Campo')`

## Widgets Compartilhados

- `PrimaryButton`: Botão principal com sombra (shared/widgets/)

## Fluxo do App

```
SplashPage → OnboardingPage (3 telas) → LoginPage ↔ RegisterPage → [Home]
```

## Backend: Supabase + Firebase (REGRA OBRIGATÓRIA)

**Supabase** é o backend principal:
- Banco de dados (PostgreSQL)
- Auth (email/senha, magic link)
- RLS (Row Level Security) para proteção por linha
- Storage (imagens, arquivos)
- Realtime (notificações, ranking)

**Firebase** é usado APENAS para:
- Google Sign-In (obter ID Token do Google)
- **NUNCA** usar Firebase para banco, auth próprio, ou storage

**Fluxo de login com Google:**
```
1. google_sign_in → Google ID Token
2. Supabase.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: googleIdToken)
3. Sessão gerenciada 100% pelo Supabase
```

**Regras:**
- Todo CRUD vai para Supabase (não Firebase)
- Sessão/token gerenciados pelo Supabase Auth
- `SupabaseClient` injetado via get_it no DI
- Datasources remotos usam `supabase.from('tabela')` para queries
- Firebase NÃO gerencia usuários — apenas provê o token Google

## Packages Principais

- `flutter_bloc` - Gerenciamento de estado
- `dartz` - Either para error handling funcional
- `get_it` - Injeção de dependências
- `equatable` - Comparação de objetos
- `shared_preferences` - Cache local
- `supabase_flutter` - Backend principal (banco, auth, storage)
- `google_sign_in` - Login com Google (token para Supabase)
- `firebase_core` - Inicialização Firebase (apenas para Google Sign-In)
