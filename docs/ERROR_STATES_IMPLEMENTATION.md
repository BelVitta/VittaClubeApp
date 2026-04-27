# Error States Implementation - Vita Clube

## Implementado do Figma Design
Design Source: https://www.figma.com/design/nNc2umOfTeoX0itneDki1b/Vitta-Clube-App?node-id=34-2986

## Visão Geral

Sistema completo de estados de erro reutilizáveis seguindo Clean Architecture e design do Figma.

## Arquivos Criados

### 1. Widget Genérico de Erro
**`lib/shared/widgets/error_states/error_state_widget.dart`**

Widget reutilizável para exibir qualquer tipo de erro.

**Props:**
```dart
ErrorStateWidget({
  required String illustrationUrl,  // URL da ilustração
  required String title,             // Título do erro
  required String message,           // Mensagem descritiva
  String buttonText = 'Tentar Novamente',
  required VoidCallback onButtonPressed,
  bool showButton = true,           // Mostrar/ocultar botão
})
```

**Características:**
- Ilustração de 201.573px
- Título: Outfit Medium, 24px
- Mensagem: Outfit Regular, 14px
- Botão: PrimaryButton reutilizável
- Centralizado verticalmente
- Padding horizontal de 16px

### 2. Página de Sem Conexão
**`lib/features/error/presentation/pages/no_connection_page.dart`**

Página específica para erro de falta de conexão com internet.

**Props:**
```dart
NoConnectionPage({
  VoidCallback? onRetry,         // Callback ao clicar em Recarregar
  bool showNavigation = true,    // Mostrar barra de navegação
})
```

**Features:**
- Background gradient circular no topo
- Status bar
- Ilustração "No Connection"
- Texto "Sem Conexão"
- Mensagem descritiva
- Botão "Recarregar"
- Bottom navigation (opcional)

### 3. Helper de Conectividade
**`lib/core/utils/connectivity_helper.dart`**

Utilitários para lidar com erros de conexão.

**Métodos:**

```dart
// Navega para página de sem conexão
ConnectivityHelper.showNoConnectionPage(
  context,
  onRetry: () {
    // Lógica de retry
  },
  showNavigation: true,
);

// Substitui tela atual
ConnectivityHelper.replaceWithNoConnectionPage(context);

// Exibe bottom sheet
ConnectivityHelper.showNoConnectionBottomSheet(
  context,
  onRetry: () {
    // Lógica de retry
  },
);
```

### 4. Exemplos de Estados de Erro
**`lib/shared/widgets/error_states/error_states_examples.dart`**

Coleção de estados de erro pré-configurados.

**Disponíveis:**

| Método | Descrição | Botão |
|--------|-----------|-------|
| `serverError()` | Erro 500/503 | Tentar Novamente |
| `notFoundError()` | Erro 404 | Voltar |
| `noDataError()` | Sem dados | Atualizar |
| `permissionError()` | Erro 403 | Voltar |
| `timeoutError()` | Timeout | Tentar Novamente |
| `genericError()` | Erro genérico | Tentar Novamente |
| `maintenanceError()` | Manutenção | Sem botão |
| `sessionExpiredError()` | Sessão expirada | Fazer Login |

## Como Usar

### 1. Exibir Página de Sem Conexão

```dart
// Opção 1: Navegação simples
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => NoConnectionPage(
      onRetry: () {
        // Lógica de retry
        Navigator.pop(context);
      },
    ),
  ),
);

// Opção 2: Usando helper
ConnectivityHelper.showNoConnectionPage(
  context,
  onRetry: () async {
    // Verificar conexão
    bool hasConnection = await checkConnection();
    if (hasConnection) {
      Navigator.pop(context);
      // Recarregar dados
    }
  },
);
```

### 2. Usar Widget Genérico de Erro

```dart
// Em qualquer página
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ErrorStateWidget(
        illustrationUrl: 'https://...',
        title: 'Erro Personalizado',
        message: 'Descrição do erro aqui.',
        buttonText: 'Ação',
        onButtonPressed: () {
          // Ação customizada
        },
      ),
    );
  }
}
```

### 3. Usar Estados Pré-configurados

```dart
import 'package:vita_clube/shared/widgets/error_states/error_states_examples.dart';

// Em um builder
Widget build(BuildContext context) {
  return Scaffold(
    body: ErrorStatesExamples.serverError(
      onRetry: () {
        // Tentar novamente
      },
    ),
  );
}

// Ou timeout
ErrorStatesExamples.timeoutError(
  onRetry: () => _fetchData(),
);

// Ou sessão expirada
ErrorStatesExamples.sessionExpiredError(
  onLogin: () => Navigator.pushNamed(context, '/login'),
);
```

### 4. Integrar com BLoC

```dart
BlocBuilder<DataBloc, DataState>(
  builder: (context, state) {
    if (state is DataLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (state is DataError) {
      // Verificar tipo de erro
      if (state.error is NetworkException) {
        return ErrorStatesExamples.timeoutError(
          onRetry: () => context.read<DataBloc>().add(FetchData()),
        );
      }

      if (state.error is ServerException) {
        return ErrorStatesExamples.serverError(
          onRetry: () => context.read<DataBloc>().add(FetchData()),
        );
      }

      // Erro genérico
      return ErrorStatesExamples.genericError(
        message: state.error.toString(),
        onRetry: () => context.read<DataBloc>().add(FetchData()),
      );
    }

    if (state is DataLoaded) {
      return _buildContent(state.data);
    }

    return Container();
  },
)
```

### 5. Bottom Sheet de Erro

```dart
// Quando detectar erro de rede
void _handleNetworkError() {
  ConnectivityHelper.showNoConnectionBottomSheet(
    context,
    onRetry: () async {
      await _retryOperation();
    },
  );
}
```

## Assets do Figma

**Ilustração Sem Conexão:**
- URL: `b3b0bee8-e330-4c50-933a-7ea0862896f6`
- Dimensões: 201.573px × 201.573px

**Ícones de Navegação:**
- Home: `145362af-1640-40bf-8bf6-6c569c636551`
- Icon 2: `d028efd3-7a89-40a3-a3a5-4b76631cec29`
- Icon 3: `709ab36a-e1f9-4af9-bcd1-7536452623cd`
- Icon 4: `565651a5-68b0-4474-8566-bc35fcec30a6`
- Icon 5: `4130bcbb-abdc-48cb-a560-408452c3efbf`

## Design Tokens

### Cores
```dart
Título:    #031535 (AppTheme.primaryText)
Mensagem:  #6D7F95 (AppTheme.secondaryText)
Botão BG:  #2C4156 (AppTheme.primaryColor)
Botão Text:#FEFEFE (White)
Borda:     #EBEEF2
```

### Tipografia
```dart
Título:   Outfit Medium, 24px, spacing 0.12px
Mensagem: Outfit Regular, 14px, spacing 0.07px, height 1.07
Botão:    Plus Jakarta Sans SemiBold, 16px, spacing 0.08px
```

### Espaçamentos
```dart
Ilustração → Título:  10px
Título → Mensagem:    9px
Mensagem → Botão:     16px
Padding horizontal:   16px
```

## Exemplo Completo: Tratamento de Erros em UseCase

```dart
// 1. Definir exceptions customizadas
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

// 2. No repository
Future<Either<Failure, Data>> getData() async {
  try {
    final response = await dataSource.getData();
    return Right(response);
  } on NetworkException {
    return Left(NetworkFailure('Sem conexão'));
  } on ServerException {
    return Left(ServerFailure('Erro no servidor'));
  } catch (e) {
    return Left(UnknownFailure(e.toString()));
  }
}

// 3. Na UI
BlocListener<DataBloc, DataState>(
  listener: (context, state) {
    if (state is DataError) {
      if (state.failure is NetworkFailure) {
        ConnectivityHelper.showNoConnectionPage(
          context,
          onRetry: () {
            context.read<DataBloc>().add(RetryFetch());
          },
        );
      }
    }
  },
  child: BlocBuilder<DataBloc, DataState>(
    builder: (context, state) {
      // Build UI
    },
  ),
)
```

## Customização

### Criar Novo Estado de Erro

```dart
// Novo estado customizado
Widget myCustomError() {
  return ErrorStateWidget(
    illustrationUrl: 'URL_DA_ILUSTRAÇÃO',
    title: 'Título Customizado',
    message: 'Mensagem detalhada do erro',
    buttonText: 'Ação Customizada',
    onButtonPressed: () {
      // Lógica específica
    },
  );
}
```

### Estilizar Botão Diferente

```dart
// Sem usar PrimaryButton, criar custom
ErrorStateWidget(
  // ... outras props
  showButton: false, // Ocultar botão padrão
);

// E adicionar seu próprio botão abaixo
```

## Testing

### Unit Tests

```dart
test('ErrorStateWidget should display title and message', () {
  // Test widget properties
});

test('NoConnectionPage should call onRetry when button pressed', () {
  // Test callback
});
```

### Widget Tests

```dart
testWidgets('ErrorStateWidget shows all elements', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ErrorStateWidget(
        illustrationUrl: 'https://test.com/image.png',
        title: 'Test Error',
        message: 'Test message',
        onButtonPressed: () {},
      ),
    ),
  );

  expect(find.text('Test Error'), findsOneWidget);
  expect(find.text('Test message'), findsOneWidget);
  expect(find.text('Tentar Novamente'), findsOneWidget);
});
```

## Próximos Passos

### Funcionalidades Futuras

1. **Adicionar Connectivity Package**
   ```yaml
   dependencies:
     connectivity_plus: ^5.0.0
   ```

2. **Monitoramento de Conexão em Tempo Real**
   ```dart
   class ConnectivityService {
     Stream<ConnectivityResult> get onConnectivityChanged;
     Future<bool> checkConnection();
   }
   ```

3. **Retry Logic com Exponential Backoff**
   ```dart
   class RetryHelper {
     Future<T> retry<T>(
       Future<T> Function() operation,
       {int maxAttempts = 3}
     );
   }
   ```

4. **Analytics de Erros**
   - Integrar com Firebase Crashlytics
   - Log de erros de rede
   - Métricas de retry

5. **Cache Local**
   - Exibir dados em cache quando offline
   - Sincronizar quando conexão retornar

## Troubleshooting

### Ilustração não carrega
- Verificar URL do Figma
- Implementar fallback com ícone
- Baixar e salvar localmente

### Botão não responde
- Verificar se `onButtonPressed` está definido
- Verificar `showButton = true`

### Layout quebrado
- Verificar SafeArea
- Padding horizontal de 16px
- Width do container = 340px máximo

## Recursos Adicionais

- [Material Design Error States](https://material.io/design/communication/empty-states.html)
- [Flutter Error Handling Best Practices](https://dart.dev/guides/language/error-handling)
- [BLoC Error Handling](https://bloclibrary.dev/#/faqs)

## Convenções

- Sempre usar `ErrorStateWidget` para consistência
- Títulos em sentence case
- Mensagens descritivas e úteis
- Botões com ações claras
- Evitar jargão técnico para o usuário
