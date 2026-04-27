# Quick Start - Estados de Erro

## Uso Básico

### 1. Exibir Erro de Sem Conexão

```dart
import 'package:vita_clube/features/error/presentation/pages/no_connection_page.dart';

// Navegar para tela de erro
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => NoConnectionPage(
      onRetry: () {
        Navigator.pop(context);
        // Recarregar dados
      },
    ),
  ),
);
```

### 2. Usar Helper (Recomendado)

```dart
import 'package:vita_clube/core/utils/connectivity_helper.dart';

// Exibir página
ConnectivityHelper.showNoConnectionPage(
  context,
  onRetry: () {
    Navigator.pop(context);
  },
);

// Ou como bottom sheet
ConnectivityHelper.showNoConnectionBottomSheet(
  context,
  onRetry: () {
    // Retry logic
  },
);
```

### 3. Estados Pré-configurados

```dart
import 'package:vita_clube/shared/widgets/error_states/error_states_examples.dart';

// Erro de servidor
ErrorStatesExamples.serverError(
  onRetry: () => _fetchData(),
);

// Timeout
ErrorStatesExamples.timeoutError(
  onRetry: () => _retry(),
);

// Sessão expirada
ErrorStatesExamples.sessionExpiredError(
  onLogin: () => Navigator.pushNamed(context, '/login'),
);

// Sem dados
ErrorStatesExamples.noDataError(
  onRefresh: () => _refresh(),
);
```

### 4. Widget Customizado

```dart
import 'package:vita_clube/shared/widgets/error_states/error_state_widget.dart';

ErrorStateWidget(
  illustrationUrl: 'https://...',
  title: 'Seu Título',
  message: 'Sua mensagem descritiva',
  buttonText: 'Ação',
  onButtonPressed: () {
    // Sua lógica
  },
)
```

## Integração com BLoC

```dart
BlocBuilder<MyBloc, MyState>(
  builder: (context, state) {
    // Loading
    if (state is Loading) {
      return Center(child: CircularProgressIndicator());
    }

    // Error
    if (state is Error) {
      return ErrorStatesExamples.genericError(
        message: state.message,
        onRetry: () => context.read<MyBloc>().add(Retry()),
      );
    }

    // Success
    return _buildContent();
  },
)
```

## Exemplo: Detectar Erro de Rede

```dart
try {
  final response = await api.getData();
  // Processar resposta
} on SocketException {
  // Erro de conexão
  ConnectivityHelper.showNoConnectionPage(context);
} on TimeoutException {
  // Timeout
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      content: ErrorStatesExamples.timeoutError(
        onRetry: () {
          Navigator.pop(context);
          _retry();
        },
      ),
    ),
  );
}
```

## Estados Disponíveis

| Estado | Quando Usar | Botão |
|--------|-------------|-------|
| No Connection | Sem internet | Recarregar |
| Server Error | Erro 500/503 | Tentar Novamente |
| Not Found | Erro 404 | Voltar |
| Timeout | Operação demorou | Tentar Novamente |
| Permission | Erro 403 | Voltar |
| Session Expired | Token expirado | Fazer Login |
| No Data | Sem resultados | Atualizar |
| Maintenance | Manutenção | Nenhum |
| Generic | Erro desconhecido | Tentar Novamente |

## Testar Diferentes Estados

No seu código de teste, force diferentes erros:

```dart
// Sem conexão
throw NetworkException();

// Servidor
throw ServerException();

// Timeout
throw TimeoutException('Timeout');

// Permissão
throw PermissionException();
```

## Estrutura de Arquivos

```
lib/
├── core/utils/
│   └── connectivity_helper.dart       ← Helpers
├── features/error/presentation/pages/
│   └── no_connection_page.dart        ← Página sem conexão
└── shared/widgets/error_states/
    ├── error_state_widget.dart        ← Widget genérico
    └── error_states_examples.dart     ← Estados pré-configurados
```

## Checklist de Implementação

- [x] Widget genérico de erro criado
- [x] Página de sem conexão criada
- [x] Helper de conectividade criado
- [x] Estados de exemplo criados
- [ ] Adicionar connectivity_plus package
- [ ] Implementar monitoramento de rede
- [ ] Adicionar analytics de erro
- [ ] Implementar retry com backoff

## Próximos Passos

1. Testar em diferentes cenários
2. Adicionar ilustrações locais
3. Implementar connectivity check real
4. Adicionar testes unitários

## Documentação Completa

Consulte: `ERROR_STATES_IMPLEMENTATION.md`
