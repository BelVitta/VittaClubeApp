# Home Page Implementation - Vita Clube

## Implementado do Figma Design
Design Source: https://www.figma.com/design/nNc2umOfTeoX0itneDki1b/Vitta-Clube-App?node-id=20-196

## Estrutura Criada

### 1. Domain Layer (`lib/features/home/domain/entities/`)
- **PlanStatusEntity**: Entidade que representa o status do plano do usuário
  - `currentPlan`: Plano atual do usuário
  - `nextPlan`: Próximo plano disponível
  - `progress`: Progresso para o próximo nível (0.0 a 1.0)

- **QuickActionEntity**: Entidade que representa ações rápidas
  - `id`: Identificador único
  - `title`: Título da ação
  - `iconUrl`: URL do ícone
  - `route`: Rota de navegação

### 2. Presentation Layer

#### Widgets (`lib/features/home/presentation/widgets/`)

1. **PlanBanner** (`plan_banner.dart`)
   - Exibe o status do plano do usuário
   - Mostra o badge do plano
   - Inclui barra de progresso
   - Props:
     - `currentPlan`: Nome do plano atual
     - `nextPlan`: Nome do próximo plano
     - `progress`: Progresso (0.0 a 1.0)
     - `badgeUrl`: URL da imagem do badge

2. **QuickActionCard** (`quick_action_card.dart`)
   - Card clicável para ações rápidas
   - Props:
     - `title`: Título da ação
     - `iconUrl`: URL do ícone
     - `onTap`: Callback ao clicar

3. **EmptyConsultationState** (`empty_consultation_state.dart`)
   - Estado vazio para histórico de consultas
   - Props:
     - `illustrationUrl`: URL da ilustração

#### Página (`lib/features/home/presentation/pages/`)

**HomePage** (`home_page.dart`)
- Página inicial completa seguindo o design do Figma
- Componentes:
  - Header com saudação e botão de notificações
  - Banner de status do plano
  - Grid de ações rápidas (Planos, Pagar, Benefícios)
  - Seção de histórico de consultas com estado vazio
  - Barra de navegação inferior

### 3. Shared Widgets (`lib/shared/widgets/`)

**AppBottomNavigation** (`app_bottom_navigation.dart`)
- Barra de navegação inferior reutilizável
- Props:
  - `currentIndex`: Índice da aba atual
  - `onTap`: Callback ao trocar de aba
  - `iconUrls`: Lista de URLs dos ícones

## Assets Utilizados

Todos os assets são carregados via URL do Figma:
- Badge do plano
- Ícones de ações rápidas
- Ilustração de estado vazio
- Ícones da barra de navegação
- Ícone de notificação

## Integração

A HomePage foi integrada ao fluxo de navegação:
```
SplashPage → OnboardingPage → LoginPage → HomePage
```

O arquivo `login_page.dart` foi atualizado para navegar para a HomePage após login bem-sucedido.

## Como Testar

1. Execute o app: `flutter run`
2. Navegue pelo onboarding
3. Faça login (ou crie uma conta)
4. A HomePage será exibida automaticamente

## Atualizações - Sistema de Badges

### ✅ Implementado (06/02/2026)

**Sistema de Níveis de Plano:**
- Enum `PlanLevel` com 5 níveis (None, Bronze, Silver, Gold, Diamond)
- Cores específicas por nível
- Badge URLs dinâmicas
- Barra de progresso com cores customizadas

**Histórico de Consultas:**
- Widget `ConsultationHistoryItem` para exibir consultas
- Suporte a estado vazio e estado com dados
- Entity `ConsultationEntity` para modelar consultas
- Formatação de datas com pacote `intl`

**Atualizações em Componentes:**
- `PlanBanner` refatorado para usar `PlanLevel`
- `HomePage` com suporte a consultas dinâmicas
- Espaçamento ajustado conforme design Figma

**Documentação Adicional:**
- `BADGES_IMPLEMENTATION.md` - Guia completo do sistema de badges
- `QUICK_START_BADGES.md` - Guia rápido para testar estados

## Próximos Passos (TODOs no código)

1. ✅ Sistema de badges com níveis de plano
2. ✅ Histórico de consultas com dados
3. Implementar navegação para tela de notificações
4. Implementar navegação para tela de planos
5. Implementar navegação para tela de pagamento
6. Implementar navegação para tela de benefícios
7. Implementar funcionalidade das outras abas da navegação inferior
8. Implementar detalhes da consulta
9. Baixar badges de Prata, Ouro e Diamante do Figma
10. Conectar com backend real para dados dinâmicos
11. Adicionar BLoC/estado para gerenciar dados da home

## Design System Utilizado

Conforme `lib/core/theme/app_theme.dart`:
- **Cores**:
  - Primary: #2C4156
  - Secondary Text: #6D7F95
  - Border: #EBEEF2
- **Fontes**:
  - Outfit (títulos e headings)
  - Plus Jakarta Sans (corpo e botões)
- **Componentes**:
  - Border radius: 16px para cards
  - Padding: 16px padrão
  - Gaps: 4px, 8px, 12px, 16px

## Arquitetura

Seguindo Clean Architecture:
- ✅ Domain: Entities puras (sem dependências Flutter)
- ✅ Presentation: Widgets e Pages (depende de Domain)
- ⏳ Data: Ainda não implementado (para integração com backend)
- ⏳ Use Cases: Ainda não implementado (para lógica de negócio)

Para completar a arquitetura, adicione:
- Data sources (mock ou remote)
- Repository implementations
- Use cases para buscar dados da home
- BLoC para gerenciar estado
