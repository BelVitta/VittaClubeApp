# ANALISE DE FUNCIONALIDADES - VITA CLUBE

**Data:** 2026-02-28
**Objetivo:** Comparar o estado atual da codebase com a especificacao completa do projeto

---

## 1. RESUMO EXECUTIVO

### O que JA EXISTE na codebase (implementado):
- Splash + Onboarding (3 telas) + Login + Registro
- Sistema de autenticacao com mock data (email/senha + placeholder Google)
- Home Page com banner de patente, progress bar, acoes rapidas
- Navegacao bottom com 5 abas (Home, Profissionais, Carteirinha, Ranking, Perfil)
- Tela de Profissionais com filtro por especialidade
- Carteirinha digital com QR Code e historico de transacoes
- Ranking/Leaderboard + aba de Sorteios
- Perfil com sub-paginas (Dados Pessoais, Notificacoes, Privacidade, Seguranca)
- Tela de Planos (mensal R$34.99, semestral R$29.99, anual R$29.99)
- Tela de Notificacoes com feed mock
- Sistema de Indicacoes (Indique e Ganhe) com logica de negocios completa
- Sistema de Progressao de Patentes (Badge Progress) com regras de upgrade
- Servicos de negocio: descontos, limite de consultas, periodo de carencia, guard de assinatura
- Painel Admin completo com CRUD para 12 entidades
- Clean Architecture + BLoC + DI (get_it) + dartz (Either)

### O que FALTA ou precisa AJUSTE:
- Backend real (tudo usa mock data)
- Fluxo de pagamento completo (cartao + PIX)
- Sistema de inadimplencia
- Notificacoes push/SMS/email reais
- Conformidade LGPD completa
- Validacao de email por token no cadastro
- Recuperacao de senha funcional
- Mecanica detalhada de sorteios

---

## 2. COMPARATIVO DETALHADO POR FUNCIONALIDADE

### 2.1 AUTENTICACAO E CADASTRO

| Requisito | Status | Detalhes |
|-----------|--------|----------|
| Login email/senha | IMPLEMENTADO | AuthBloc + LoginPage + LoginUseCase, mock data |
| Login Google | PARCIAL | GoogleSignInUseCase existe, botao na UI, mas nao funcional |
| Registro com nome, CPF, phone, email, senha | IMPLEMENTADO | RegisterPage com validacao completa |
| Validacao CPF (formato + unicidade) | IMPLEMENTADO | Validators.validateCPF() |
| Validacao email (formato + unicidade) | IMPLEMENTADO | Validators.validateEmail() |
| Validacao senha >= 8 chars | IMPLEMENTADO | Validators.validatePassword() |
| Envio de token por email p/ validacao | NAO IMPLEMENTADO | Nenhum fluxo de verificacao por token |
| Tela de validar token | NAO IMPLEMENTADO | Nao existe |
| Recuperacao de senha | PARCIAL | ForgotPasswordPage existe como placeholder, sem logica |
| Deteccao de papel (user vs admin) | IMPLEMENTADO | UserEntity.role = 'user' ou 'admin', SplashBloc redireciona |
| Cache de sessao | IMPLEMENTADO | SharedPreferences com JSON do usuario |

**Gaps:** Falta verificacao de email por token, recuperacao de senha funcional, e integracao com backend real.

---

### 2.2 SISTEMA DE PATENTES/BADGES (7 Niveis na spec, 4 implementados)

| Requisito (Spec) | Status | Implementacao Atual |
|-------------------|--------|---------------------|
| Bronze: 10% desconto, 4 consultas/mes | IMPLEMENTADO | DiscountService + ConsultationLimitService |
| Prata: 15% desconto, 8 consultas/mes | IMPLEMENTADO | Mesmos servicos |
| Ouro: 20% desconto, 12 consultas/mes | IMPLEMENTADO | Mesmos servicos |
| Diamante: 30% desconto, 20 consultas/mes | IMPLEMENTADO | Mesmos servicos |
| Bronze -> Prata: 6 meses + 4 consultas | IMPLEMENTADO | BadgeProgressEntity.canUpgradeToSilver |
| Prata -> Ouro: +6 meses + 6 consultas + 2 indicacoes | PARCIAL | Implementado como 12 meses total (spec diz +6 meses) |
| Ouro -> Diamante: +12 meses + 14 consultas + 3 indicacoes + plano anual | PARCIAL | Implementado como 24 meses total |
| Progressao automatica | IMPLEMENTADO | CheckBadgeUpgradeUseCase |
| Badges visuais (icones, cores) | IMPLEMENTADO | PlanLevel enum com cores e icones |
| Sorteio por nivel | PARCIAL | DrawEntity tem eligibleBadgeLevels, mas sem mecanica real |

**Gaps:**
- A spec menciona "7 niveis" no titulo mas define apenas 4 niveis na tabela. A implementacao tem 4 + 2 estados negativos (inadimplente, cancelado) = 6 estados no PlanLevel enum.
- Progressao automatica existe na logica mas falta trigger (ex: apos cada consulta verificar upgrade).
- Falta UI de notificacao de upgrade de patente.

---

### 2.3 MECANICA DE SORTEIOS

| Requisito | Status | Detalhes |
|-----------|--------|----------|
| DrawEntity com dados do sorteio | IMPLEMENTADO | id, prizeName, drawDate, status, participantCount, winnerId, winnerName, eligibleBadgeLevels |
| Admin CRUD de sorteios | IMPLEMENTADO | DrawBloc + AdminDrawsListPage + AdminDrawFormPage |
| Aba de Sorteio no Ranking | IMPLEMENTADO | RankingPage tab 2 |
| Sorteio mensal (todos os niveis) | NAO IMPLEMENTADO | Sem logica de periodicidade automatica |
| Sorteio exclusivo Diamante | NAO IMPLEMENTADO | eligibleBadgeLevels existe no model mas sem filtro funcional |
| Notificacao de resultado do sorteio | NAO IMPLEMENTADO | Mock notification referencia sorteios, sem push real |
| Mecanica de participacao automatica | NAO IMPLEMENTADO | Sem logica de inscricao automatica baseada em plano ativo |
| Bloqueio de participacao para inadimplentes | NAO IMPLEMENTADO | Sem verificacao de status do plano |

**Gaps:** A estrutura de dados existe, mas toda a mecanica de sorteios (inscricao, execucao, notificacao, periodicidade) nao esta implementada. E essencialmente um CRUD admin sem o fluxo do usuario.

---

### 2.4 PAGAMENTOS E ASSINATURA

| Requisito | Status | Detalhes |
|-----------|--------|----------|
| PlanEntity com tipos de assinatura | IMPLEMENTADO | SubscriptionType: monthly, semiannual, annual |
| Tela de selecao de planos | IMPLEMENTADO | PlansPage com 3 cards animados |
| ChoosePlanPage | PARCIAL | Referenciado mas implementacao limitada |
| Pagamento via cartao | NAO IMPLEMENTADO | Sem integracao com gateway |
| Pagamento via PIX (QR 24h) | NAO IMPLEMENTADO | Sem geracao real de QR PIX |
| 3 tentativas automaticas cartao | NAO IMPLEMENTADO | Sem logica de retry |
| Admin de pagamentos (CRUD) | IMPLEMENTADO | PaymentAdminEntity + AdminPaymentsListPage |
| Historico de transacoes (usuario) | PARCIAL | CardPage mostra mock de historico |
| Oferta parcelamento 3x (dia 20) | NAO IMPLEMENTADO | |
| Aviso via PIX | NAO IMPLEMENTADO | |

**Gaps:** O fluxo completo de pagamento (selecao -> metodo -> processamento -> confirmacao) nao esta implementado. Falta integracao com gateway de pagamento (Stripe, MercadoPago, etc).

---

### 2.5 INADIMPLENCIA

| Requisito | Status | Detalhes |
|-----------|--------|----------|
| Bloqueio de agendamento | NAO IMPLEMENTADO | |
| Bloqueio de sorteios | NAO IMPLEMENTADO | |
| Bloqueio de descontos | NAO IMPLEMENTADO | |
| Manter visualizacao de historico | NAO IMPLEMENTADO | Nao ha verificacao de inadimplencia |
| Manter carteirinha visivel | NAO IMPLEMENTADO | |
| 3 tentativas automaticas cartao | NAO IMPLEMENTADO | |
| Oferta parcelamento 3x (dia 20) | NAO IMPLEMENTADO | |
| Aviso via Pix | NAO IMPLEMENTADO | |
| PlanLevel.inadimplente existe | PARCIAL | Enum value existe mas sem logica associada |

**Gaps:** O estado `inadimplente` existe no enum PlanLevel, mas nenhuma logica de deteccao, bloqueio, ou cobranca esta implementada. Feature inteira a desenvolver.

---

### 2.6 SISTEMA DE INDICACOES (Indique e Ganhe)

| Requisito | Status | Detalhes |
|-----------|--------|----------|
| Gerar codigo de indicacao | IMPLEMENTADO | CreateReferralUseCase + ReferralBloc |
| Limite 10 indicacoes/mes por CPF | IMPLEMENTADO | CreateReferralUseCase valida limite |
| Validar codigo na inscricao do indicado | IMPLEMENTADO | ValidateReferralUseCase |
| Indicado ativo por 60 dias (requisito recompensa) | IMPLEMENTADO | ReferralEntity.isEligibleForReward |
| Indicado completou 1 consulta (requisito) | IMPLEMENTADO | referredCompletedConsultation flag |
| Reivindicar recompensa | IMPLEMENTADO | ClaimRewardUseCase |
| Tela de indicacoes com stats | IMPLEMENTADO | ReferralPage com contadores |
| Bonus Indicador (R$ X em creditos) | NAO IMPLEMENTADO | Logica de creditos nao existe |
| Bonus Indicado (X% OFF 1o mes) | NAO IMPLEMENTADO | Sem desconto automatico |
| Copiar/compartilhar codigo | PARCIAL | UI de copiar existe, sem share nativo |

**Gaps:** A mecanica de indicacao esta bem implementada (validacao, elegibilidade, limites). Faltam: valor concreto dos bonus, sistema de creditos, desconto automatico para indicado, e share nativo.

---

### 2.7 AGENDAMENTO DE CONSULTAS

| Requisito | Status | Detalhes |
|-----------|--------|----------|
| Lista de profissionais | IMPLEMENTADO | ProfessionalsPage com 5 mock |
| Filtro por especialidade | IMPLEMENTADO | Sheet de filtro por dia |
| Filtro por dia disponivel | IMPLEMENTADO | availableDays no profissional |
| Selecao de data/hora | NAO IMPLEMENTADO | |
| Confirmacao de agendamento | NAO IMPLEMENTADO | |
| Historico de consultas | PARCIAL | ConsultationEntity existe, lista mock na HomePage |
| Limite mensal por patente | IMPLEMENTADO | ConsultationLimitService |
| Preco com desconto por patente | IMPLEMENTADO | DiscountService + ConsultationPriceWidget |
| Widget de consultas restantes | IMPLEMENTADO | ConsultationLimitWidget |
| Periodo de carencia (7 dias) | IMPLEMENTADO | GracePeriodService + GracePeriodBanner |
| Guard de assinatura | IMPLEMENTADO | SubscriptionGuard + SubscriptionGuardWidget |
| Admin CRUD consultas | IMPLEMENTADO | ConsultationAdminEntity + BLoC + Pages |
| WhatsApp do profissional | PARCIAL | whatsappNumber no model, sem acao de abrir |

**Gaps:** Os servicos de regra de negocio (limites, descontos, carencia) estao prontos, mas o fluxo de agendamento em si (selecionar profissional -> escolher data/hora -> confirmar -> adicionar ao historico) NAO existe.

---

### 2.8 NOTIFICACOES

| Requisito | Status | Detalhes |
|-----------|--------|----------|
| Feed de notificacoes in-app | IMPLEMENTADO | NotificationsPage com mock |
| Marcar como lida | IMPLEMENTADO | Botao "marcar todas como lidas" |
| Excluir notificacao | IMPLEMENTADO | Funcionalidade de delete |
| Badge de nao lidas | IMPLEMENTADO | Indicador no icone |
| Admin CRUD de templates | IMPLEMENTADO | NotificationTemplateEntity + pages |
| Push notifications reais | NAO IMPLEMENTADO | Sem Firebase Messaging |
| SMS | NAO IMPLEMENTADO | |
| Email transacional | NAO IMPLEMENTADO | |
| Notificacao de sorteio | NAO IMPLEMENTADO | Mock apenas |
| Notificacao de upgrade de patente | NAO IMPLEMENTADO | |
| Notificacao de inadimplencia | NAO IMPLEMENTADO | |
| Configuracoes de notificacao | IMPLEMENTADO | NotificationSettingsPage com toggles |

**Gaps:** UI de notificacoes pronta. Falta integracao com servicos de push (Firebase Cloud Messaging), SMS, e email.

---

### 2.9 CARTEIRINHA DIGITAL

| Requisito | Status | Detalhes |
|-----------|--------|----------|
| Exibicao de carteirinha | IMPLEMENTADO | CardPage com nome e codigo |
| QR Code do membro | IMPLEMENTADO | QR code sheet |
| Historico de economia | IMPLEMENTADO | Resumo de economia na CardPage |
| Historico de transacoes | IMPLEMENTADO | Lista de transacoes mock |
| Scanner QR (admin) | IMPLEMENTADO | AdminQrScannerPage |

**Status:** Funcionalidade mais completa do app. Falta apenas dados reais.

---

### 2.10 PERFIL E LGPD

| Requisito | Status | Detalhes |
|-----------|--------|----------|
| Visualizar/editar dados pessoais | IMPLEMENTADO | PersonalDataPage |
| Configuracoes de notificacao | IMPLEMENTADO | NotificationSettingsPage |
| Privacidade e dados | PARCIAL | PrivacyDataPage existe como placeholder |
| Seguranca (trocar senha) | PARCIAL | SecurityPage existe como placeholder |
| Logout | IMPLEMENTADO | Botao no ProfilePage |
| Exclusao de conta (LGPD) | NAO IMPLEMENTADO | |
| Exportacao de dados (LGPD) | NAO IMPLEMENTADO | |
| Consentimento explicito | NAO IMPLEMENTADO | |
| Termos de uso/politica de privacidade | NAO IMPLEMENTADO | |

**Gaps:** As telas existem mas estao como placeholders. LGPD requer: exclusao de conta, exportacao de dados, consentimento, e termos.

---

### 2.11 PAINEL ADMINISTRATIVO

| Requisito | Status | Detalhes |
|-----------|--------|----------|
| Dashboard com grid de modulos | IMPLEMENTADO | AdminDashboardPage com 12 cards |
| CRUD Especialidades | IMPLEMENTADO | Completo |
| CRUD Profissionais | IMPLEMENTADO | Completo |
| CRUD Planos | IMPLEMENTADO | Completo |
| CRUD Usuarios | IMPLEMENTADO | Completo |
| CRUD Pagamentos | IMPLEMENTADO | Completo |
| CRUD Consultas | IMPLEMENTADO | Completo |
| CRUD Notificacoes (templates) | IMPLEMENTADO | Completo |
| CRUD Sorteios | IMPLEMENTADO | Completo |
| CRUD Cupons | IMPLEMENTADO | Completo |
| CRUD Ranking | IMPLEMENTADO | Completo |
| CRUD Motivos Cancelamento | IMPLEMENTADO | Completo |
| CRUD Badges | IMPLEMENTADO | Completo |
| Scanner QR | IMPLEMENTADO | AdminQrScannerPage |
| Busca/filtro em listas | IMPLEMENTADO | AdminSearchBar em todas listas |
| Confirmacao de exclusao | IMPLEMENTADO | AdminDeleteDialog |

**Status:** Modulo mais completo do app. 12 entidades com CRUD completo, BLoC, use cases, e mock data.

---

## 3. FLUXO COMPARATIVO (Spec vs Implementacao)

### Fluxo da Spec:
```
App abre -> Splash 3s -> Onboarding (3 telas) -> Escolha (Login/Cadastro)
  Cadastro -> Valida CPF -> Valida Email -> Valida Senha -> Token email -> Conta Ativa
  Login -> Credenciais -> Autenticado
    -> Verifica plano ativo?
      Nao -> Home sem plano -> Banner escolher plano -> Lista planos -> Pagamento (Cartao/PIX)
        -> Plano Bronze Ativado -> Carencia 7 dias -> Home Bronze
      Sim -> Home com plano
```

### Fluxo Implementado:
```
App abre -> Splash 2s -> [cache?]
  Sem cache + primeiro acesso -> Onboarding (3 telas) -> Login
  Sem cache + ja viu onboarding -> Login
  Com cache (user) -> Home
  Com cache (admin) -> Admin Dashboard

  Login -> Valida email/senha -> Mock auth -> Home ou Admin
  Cadastro -> Valida campos (CPF, email, senha) -> Mock register -> [sem token] -> Login

  Home -> Mostra banner Bronze (hardcoded 30% progresso)
       -> Acoes rapidas: Planos, Pagar, Beneficios
       -> Bottom nav: Profissionais, Carteirinha, Ranking, Perfil
```

### Diferencas no fluxo:
1. **Splash:** Spec diz 3s, implementacao usa 2s
2. **Token de email:** Spec exige, nao implementado
3. **Verificacao de plano:** Spec verifica se tem plano ativo, implementacao mostra sempre Bronze hardcoded
4. **Fluxo de pagamento:** Spec detalha Cartao vs PIX com retries, nao implementado
5. **Carencia 7 dias:** Servico existe mas nao integrado ao fluxo
6. **Home sem plano vs com plano:** Nao ha diferenciacao na UI atual

---

## 4. PRIORIZACAO DE GAPS (O QUE FAZER PRIMEIRO)

### PRIORIDADE CRITICA (Core Business - Sem isso o app nao funciona)
1. **Backend real / API** - Substituir todos mock data sources por integracao real
2. **Fluxo de pagamento completo** - Gateway de pagamento (cartao + PIX)
3. **Agendamento de consultas** - Fluxo completo de selecionar profissional -> data/hora -> confirmar
4. **Diferenciacao Home sem plano vs com plano** - Logica de verificacao de assinatura ativa

### PRIORIDADE ALTA (Features essenciais para o modelo de negocio)
5. **Sistema de inadimplencia** - Deteccao, bloqueios, cobranca automatica
6. **Verificacao de email por token** - Completar fluxo de cadastro
7. **Recuperacao de senha** - Fluxo funcional
8. **Notificacoes push reais** - Firebase Cloud Messaging
9. **Mecanica de sorteios** - Inscricao automatica, execucao, notificacao

### PRIORIDADE MEDIA (Melhorias e compliance)
10. **LGPD completo** - Exclusao de conta, exportacao de dados, consentimento, termos
11. **Sistema de creditos (indicacoes)** - Bonus concretos para indicador/indicado
12. **Share nativo para indicacoes** - Compartilhar codigo via WhatsApp/redes
13. **Google Sign-In funcional** - Completar integracao OAuth

### PRIORIDADE BAIXA (Polish e otimizacoes)
14. **Splash 2s -> 3s** - Ajustar tempo conforme spec
15. **Trigger automatico de upgrade de patente** - Verificar apos cada consulta
16. **UI de notificacao de upgrade** - Animacao/modal ao subir de nivel
17. **WhatsApp do profissional** - Botao para abrir conversa

---

## 5. METRICAS DE COMPLETUDE

| Area | Completude | Nota |
|------|-----------|------|
| Autenticacao/Cadastro | 70% | Falta token email, recuperacao senha |
| Sistema de Patentes | 80% | Logica pronta, falta trigger e UI de upgrade |
| Sorteios | 25% | Apenas CRUD admin, sem mecanica |
| Pagamentos | 15% | Apenas selecao de plano, sem processamento |
| Inadimplencia | 5% | Enum existe, sem logica |
| Indicacoes | 75% | Logica completa, falta creditos e bonus |
| Agendamento | 30% | Lista profissionais + regras, sem fluxo |
| Notificacoes | 40% | UI pronta, sem push real |
| Carteirinha | 85% | Quase completa, falta dados reais |
| Perfil/LGPD | 45% | Telas existem, falta LGPD |
| Admin | 95% | Completo, falta dados reais |
| **GERAL** | **~50%** | Arquitetura solida, falta integracao real |

---

## 6. CONCLUSAO

A codebase tem uma **arquitetura excelente** (Clean Architecture + BLoC bem aplicados) e uma base solida de UI e regras de negocio. O painel admin esta praticamente completo. O sistema de indicacoes e progressao de patentes tem logica de negocio bem implementada.

Os maiores gaps sao na **integracao com sistemas externos**: backend/API, gateway de pagamento, push notifications, e verificacao de email. O fluxo principal do usuario (cadastrar -> pagar -> agendar consulta -> usar desconto) ainda nao esta completo de ponta a ponta.

A recomendacao e priorizar: (1) backend real, (2) fluxo de pagamento, (3) agendamento de consultas, e (4) diferenciacao de estados do usuario (sem plano, ativo, inadimplente, cancelado).
