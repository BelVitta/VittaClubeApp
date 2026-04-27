# Papeis e Permissoes — Vita Clube

> Definicao dos 3 perfis do sistema: Usuario, Admin e Financeiro.

---

## Visao Geral

```
FINANCEIRO (dono/gestor)
  └── Cria e gerencia Admins
  └── Ve tudo que o Admin ve + financeiro
  └── Toma decisoes estrategicas

ADMIN (recepcionista)
  └── Cadastros do dia a dia
  └── Valida pacientes
  └── Gerencia agenda

USUARIO (membro/paciente)
  └── Usa o cartao
  └── Agenda consultas
  └── Usa descontos
```

**Hierarquia:** Financeiro > Admin > Usuario

---

## 1. USUARIO (role: `user`)

Quem e: o paciente/membro que paga o plano e usa os beneficios.

### Telas que ja existem

| Tela | O que faz |
|------|-----------|
| Home | Ve plano atual, badge, consultas recentes |
| Profissionais | Lista profissionais por especialidade |
| Cartao | Carteirinha digital com QR |
| Perfil | Dados pessoais, plano, configuracoes |
| Planos | Escolher/trocar plano |
| Pagamentos | Historico de pagamentos |
| Indicacao | Gerar codigo de indicacao, ver status |
| Badge | Progresso no sistema de badges |

### Telas futuras

| Tela | O que faz |
|------|-----------|
| Parceiros | Lista laboratorios/clinicas parceiras, exames disponiveis, usar desconto |
| Sorteios | Ver sorteios disponiveis, participar |
| Notificacoes | Central de avisos |
| Cupons | Cupons disponiveis para uso |

---

## 2. ADMIN (role: `admin`)

Quem e: a **recepcionista** da clinica. Opera o sistema no dia a dia.

### O que o Admin faz hoje (ja implementado)

**Cadastros (CRUD completo):**
- Profissionais — cadastrar medicos, horarios, especialidade
- Especialidades — criar/editar especialidades medicas
- Planos — gerenciar planos
- Usuarios — ver/editar dados de membros

**Operacoes:**
- Consultas — agendar, remarcar, cancelar
- Pagamentos — visualizar pagamentos (somente leitura)
- Notificacoes — criar templates de notificacao
- Sorteios — criar e gerenciar sorteios
- Cupons — criar e gerenciar cupons de desconto
- Scanner QR — validar carteirinha do paciente na recepcao

**Configuracoes:**
- Motivos de cancelamento — cadastrar motivos
- Badges — configurar niveis e requisitos

### O que o Admin NAO deve fazer

| Acao | Por que nao |
|------|-------------|
| Criar outros admins | Isso e funcao do Financeiro |
| Alterar role de usuario | Isso e funcao do Financeiro |
| Ver relatorios financeiros | Recepcionista nao precisa ver faturamento |
| Excluir usuarios permanentemente | Acao destrutiva, so Financeiro |
| Alterar precos de planos | Decisao estrategica, so Financeiro |
| Ver dados financeiros consolidados | Receita, inadimplencia, etc — so Financeiro |

### Ajustes necessarios no Admin atual

O Admin hoje tem acesso a TUDO. Precisamos **restringir**:

```
REMOVER do Admin:
  - Editar campo "role" no formulario de usuario
  - Editar precos de planos (pode ver, nao editar)
  - Excluir usuarios (pode desativar, nao excluir)

MANTER no Admin:
  - Todo o resto que ja existe
  - CRUD de profissionais, especialidades, consultas
  - Visualizar pagamentos
  - Gerenciar sorteios, cupons, notificacoes
  - Scanner QR
```

---

## 3. FINANCEIRO (role: `financeiro`)

Quem e: o **dono da clinica** ou gestor financeiro. Supervisiona tudo.

### 3.1 Gestao de Equipe

| Funcionalidade | Descricao |
|----------------|-----------|
| Criar admins | Promover usuario para admin |
| Remover admins | Rebaixar admin para usuario |
| Ver lista de admins | Quem sao os admins ativos |
| Historico de acoes | Log de quem fez o que (audit_log) |

> O Financeiro e o UNICO que pode alterar o campo `role` de um usuario.

### 3.2 Dashboard Financeiro

| Funcionalidade | Dados exibidos |
|----------------|----------------|
| Receita do mes | Soma de pagamentos aprovados no periodo |
| Receita por plano | Quanto cada plano gera (mensal, semestral, anual) |
| Inadimplencia | Usuarios com pagamento pendente/cancelado |
| Evolucao mensal | Grafico de receita dos ultimos 6-12 meses |
| Ticket medio | Valor medio por assinatura |

> Dados vem das tabelas `payments` e `subscriptions` que o financeiro ja tem acesso via RLS.

### 3.3 Gestao de Membros (visao gerencial)

| Funcionalidade | Descricao |
|----------------|-----------|
| Total de membros ativos | Quantos usuarios com status `ativo` |
| Novos membros no mes | Cadastros recentes |
| Cancelamentos no mes | Quantos cancelaram + motivos mais frequentes |
| Taxa de retencao | % de membros que renovaram |
| Membros por plano | Distribuicao entre mensal/semestral/anual |
| Membros por badge | Quantos em cada nivel (bronze/prata/ouro/diamante) |

### 3.4 Gestao de Precos e Planos

| Funcionalidade | Descricao |
|----------------|-----------|
| Alterar precos | Editar valor dos planos |
| Criar/desativar planos | Gestao estrategica de planos |
| Configurar descontos | % de desconto por badge |
| Gerenciar beneficios | O que cada plano inclui |

> Admin pode VER planos. Financeiro pode EDITAR.

### 3.5 Relatorios

| Relatorio | Descricao |
|-----------|-----------|
| Faturamento mensal | Receita total, por metodo de pagamento |
| Cupons utilizados | Quantos cupons usados, impacto no faturamento |
| Consultas realizadas | Volume de consultas por periodo, por profissional |
| Sorteios | Participacao, engajamento |
| Indicacoes | Quantas indicacoes converteram, receita gerada |
| Cancelamentos | Motivos, tendencia, periodo critico |

### 3.6 Configuracoes Avancadas

| Funcionalidade | Descricao |
|----------------|-----------|
| Gerenciar parceiros | Cadastrar laboratorios, definir descontos |
| Configurar badges | Requisitos para cada nivel |
| Limites de consulta | Max consultas por badge/mes |
| Politica de cancelamento | Carencia, multa, regras |

---

## Matriz de Permissoes Completa

| Funcionalidade | Usuario | Admin | Financeiro |
|----------------|---------|-------|------------|
| **Proprio perfil** | | | |
| Ver/editar dados pessoais | ✅ | ✅ | ✅ |
| Ver carteirinha | ✅ | — | — |
| Ver badge/progresso | ✅ | — | — |
| **Planos** | | | |
| Ver planos disponiveis | ✅ | ✅ | ✅ |
| Assinar/trocar plano | ✅ | — | — |
| Criar/editar/excluir planos | — | — | ✅ |
| Alterar precos | — | — | ✅ |
| **Profissionais** | | | |
| Listar profissionais | ✅ | ✅ | ✅ |
| CRUD profissionais | — | ✅ | ✅ |
| **Especialidades** | | | |
| Ver especialidades | ✅ | ✅ | ✅ |
| CRUD especialidades | — | ✅ | ✅ |
| **Consultas** | | | |
| Ver proprias consultas | ✅ | — | — |
| CRUD todas consultas | — | ✅ | ✅ |
| **Pagamentos** | | | |
| Ver proprios pagamentos | ✅ | — | — |
| Ver todos pagamentos | — | ✅ (lista) | ✅ (lista + relatorios) |
| **Usuarios** | | | |
| Ver lista de usuarios | — | ✅ | ✅ |
| Editar dados de usuario | — | ✅ | ✅ |
| Alterar role (user↔admin) | — | — | ✅ |
| Desativar usuario | — | ✅ | ✅ |
| Excluir usuario | — | — | ✅ |
| **Sorteios** | | | |
| Participar | ✅ | — | — |
| CRUD sorteios | — | ✅ | ✅ |
| **Cupons** | | | |
| Usar cupom | ✅ | — | — |
| CRUD cupons | — | ✅ | ✅ |
| Ver impacto financeiro | — | — | ✅ |
| **Notificacoes** | | | |
| Receber notificacoes | ✅ | — | — |
| CRUD templates | — | ✅ | ✅ |
| **Indicacoes** | | | |
| Indicar amigos | ✅ | — | — |
| Ver todas indicacoes | — | ✅ | ✅ |
| **Badges** | | | |
| Ver proprio progresso | ✅ | — | — |
| Configurar requisitos | — | — | ✅ |
| **Scanner QR** | | | |
| Mostrar carteirinha | ✅ | — | — |
| Escanear/validar | — | ✅ | ✅ |
| **Relatorios** | | | |
| Dashboard financeiro | — | — | ✅ |
| Relatorio de receita | — | — | ✅ |
| Relatorio de cancelamentos | — | — | ✅ |
| Relatorio de consultas | — | — | ✅ |
| **Gestao de equipe** | | | |
| Criar admins | — | — | ✅ |
| Ver log de auditoria | — | — | ✅ |
| **Parceiros** | | | |
| Ver parceiros/descontos | ✅ | — | — |
| CRUD parceiros | — | — | ✅ |
| **Motivos cancelamento** | | | |
| CRUD motivos | — | ✅ | ✅ |

---

## Navegacao por Role

### Usuario — Bottom Navigation (4 tabs)
```
Home | Profissionais | Cartao | Perfil
```

### Admin — Dashboard Grid (como ja esta)
```
Cadastros:     Profissionais | Especialidades | Usuarios
Operacoes:     Consultas | Pagamentos | Sorteios | Cupons | Notificacoes | Scanner QR
Configuracoes: Motivos Cancelamento
```
> Removido: Planos (CRUD) e Badges dos cards do admin.
> Pagamentos continua mas somente leitura (sem relatorios).

### Financeiro — Dashboard com Metricas + Grid
```
Metricas:      Receita Mes | Membros Ativos | Inadimplencia | Cancelamentos
Gestao:        Planos | Badges | Parceiros | Equipe (Admins)
Relatorios:    Faturamento | Consultas | Indicacoes | Cupons | Cancelamentos
Operacional:   (acesso a tudo que o Admin ve, caso precise)
```

---

## Fluxo de Login por Role

```
Login
  ├── role == 'user'        → HomePage (bottom nav 4 tabs)
  ├── role == 'admin'       → AdminDashboardPage (grid operacional)
  └── role == 'financeiro'  → FinanceiroDashboardPage (metricas + gestao)
```

---

## Implementacao Sugerida

### Fase 1 — Ajustar Admin + Routing Financeiro
- Restringir Admin (remover edicao de roles, precos, exclusao)
- Criar rota financeiro no login/splash
- Criar FinanceiroDashboardPage basica

### Fase 2 — Dashboard Financeiro
- Metricas em tempo real (receita, membros, inadimplencia)
- Gestao de equipe (criar/remover admins)
- CRUD de planos e badges (movido do admin)

### Fase 3 — Relatorios
- Faturamento mensal com graficos
- Cancelamentos e motivos
- Performance de consultas e indicacoes

### Fase 4 — Parceiros
- CRUD de parceiros (financeiro)
- Aba parceiros no app do usuario
- Sistema de validacao de desconto
