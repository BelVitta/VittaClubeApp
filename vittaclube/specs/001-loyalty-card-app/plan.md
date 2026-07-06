# Implementation Plan: Aplicativo de Cartao Fidelidade em Saude

**Branch**: `main` | **Date**: 2026-06-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-loyalty-card-app/spec.md`

## Summary

Implementar e evoluir o Vitta Clube como aplicativo Flutter profissional para
cartao fidelidade em saude, preservando a arquitetura atual por features e
fortalecendo qualidade visual, performance, acessibilidade, seguranca,
conteudo comercial, SEO local em superficies indexaveis e manutencao futura.

O plano parte da codebase existente: `lib/core` concentra configuracao, tema,
DI, erros, pagamentos e servicos de regras; `lib/shared/widgets` possui
componentes reutilizaveis; `lib/features` ja segue Clean Architecture em
varias features com `domain`, `data` e `presentation`. A evolucao deve ser
incremental: completar camadas ausentes, padronizar componentes, separar a home
comercial em secoes, consolidar contratos de dados e reforcar testes e gates.

## Technical Context

**Language/Version**: Dart SDK `^3.6.1` com Flutter.

**Primary Dependencies**: Flutter Material 3, `flutter_bloc`, `equatable`,
`get_it`, `dartz`, `supabase_flutter`, `shared_preferences`, `firebase_core`,
`firebase_auth`, `google_sign_in`, `qr_flutter`, `mobile_scanner`,
`flutter_svg`, `shimmer`, `url_launcher`, `intl`, `crypto`, `google_fonts`.

**Storage**: Supabase como backend principal para auth, dados, RLS e storage;
`shared_preferences` apenas para cache local leve e sessao/flags nao sensiveis.

**Testing**: `flutter test`, `bloc_test`, `mocktail`, `flutter analyze`;
adicionar suites por feature para unit, BLoC, widget, permissao, formularios,
estados de UI e validacoes basicas de acessibilidade/responsividade.

**Target Platform**: Mobile-first para Android/iOS; Flutter Web ou landing
externa apenas para superficie publica/indexavel quando SEO local for
prioridade.

**Project Type**: Mobile app com superficies publicas/comerciais, painel
operacional admin, painel super admin/financeiro e area de parceiros.

**Performance Goals**: Telas principais percebidas como imediatas; primeira
tela comercial renderizada sem espera perceptivel; listas com carregamento
progressivo; rolagem fluida; nenhuma chamada repetida ao Supabase em rebuilds;
imagens otimizadas e fallbacks visuais.

**Constraints**: Mobile-first obrigatorio; conteudo sem placeholders; CTAs
visiveis; acessibilidade minima em toda interface; RLS e segregacao de roles;
dados financeiros e sensiveis ocultos para admin; testes automatizados como
gate; SEO local tratado fora do app mobile quando indexacao forte for exigida.

**Scale/Scope**: Produto completo com cliente, admin, super admin/financeiro e
possivel parceiro; dezenas de telas existentes e futuras; dados dinamicos de
planos, profissionais, parceiros, consultas, pagamentos, sorteios, cupons,
notificacoes e conteudo comercial.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Business outcome**: PASS. Todas as fases mapeiam funcionalidades para
  conversao, retencao, uso de beneficios, eficiencia operacional, seguranca
  financeira ou descoberta organica.
- **Trust and conversion**: PASS. A home comercial exige primeira tela clara,
  prova de confianca, CTAs estrategicos, dados reais da clinica e conteudo sem
  placeholders.
- **Mobile-first UX/UI**: PASS. O plano prioriza layout mobile, secoes
  independentes, touch targets, estados completos e verificacao em viewports
  pequenos.
- **Accessibility**: PASS. Acessibilidade minima entra como contrato: Semantics
  quando necessario, contraste, foco, labels, mensagens de erro e fontes
  escalaveis.
- **Clean architecture by feature**: PASS. A estrategia preserva
  `domain/data/presentation`, BLoC, repositories, datasources, use cases e DI.
- **Automated tests**: PASS. Testes unitarios, BLoC, widget, permissoes,
  formularios e estados de UI sao obrigatorios por feature.
- **Performance and SEO local**: PASS. Performance e tratada como requisito;
  SEO local e documentado para superficies publicas/indexaveis com recomendacao
  tecnica separada quando SEO for critico.
- **Simplicity**: PASS. O plano evita reescrita total e prioriza evolucao
  incremental sobre a estrutura ja existente.

## Project Structure

### Documentation (this feature)

```text
specs/001-loyalty-card-app/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── ui-contract.md
│   ├── data-contract.md
│   └── security-permissions-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── config/
│   ├── di/
│   ├── error/
│   ├── payment/
│   ├── services/
│   ├── theme/
│   └── utils/
├── shared/
│   └── widgets/
│       ├── buttons/
│       ├── cards/
│       ├── feedback/
│       ├── forms/
│       └── layout/
└── features/
    ├── commercial_home/
    │   ├── domain/
    │   │   ├── entities/
    │   │   ├── repositories/
    │   │   └── usecases/
    │   ├── data/
    │   │   ├── datasources/
    │   │   ├── models/
    │   │   └── repositories/
    │   └── presentation/
    │       ├── bloc/
    │       ├── pages/
    │       ├── sections/
    │       └── widgets/
    ├── plans/
    ├── professionals/
    ├── parceiro/
    ├── card/
    ├── payments/
    ├── consultation/
    ├── admin/
    ├── financeiro/
    ├── profile/
    ├── referral/
    ├── badge_progress/
    ├── notifications/
    └── auth/

test/
├── core/
├── shared/
└── features/
    └── [feature]/
        ├── domain/
        ├── data/
        ├── presentation/
        └── permissions/
```

**Structure Decision**: Manter o projeto Flutter unico e a arquitetura por
features ja existente. Criar `commercial_home` apenas se a home publica exigir
fluxo comercial separado da home autenticada atual; caso contrario, evoluir
`features/home` com subpastas `sections/` e contratos claros. Componentes
genericos entram em `shared/widgets`; componentes com regra, copy ou layout de
uma feature permanecem dentro da feature.

## Architecture Strategy

### Diagnostico da estrutura atual

- `lib/core/config` ja centraliza configuracao e Supabase.
- `lib/core/di/injection_container.dart` registra datasources, repositories,
  use cases e BLoCs.
- `lib/core/services` possui regras transversais de negocio: desconto, limite
  de consultas, carencia, guard de assinatura, contato WhatsApp e settings da
  clinica.
- `lib/core/theme/app_theme.dart` define cores, tipografia e inputs, mas ainda
  precisa virar um design system mais completo com tokens de espacamento,
  radius, elevacao, estados e estilos de botoes/cards.
- `lib/shared/widgets` ja contem botoes, bottom navigation, skeleton, estados
  de erro e widgets de assinatura/consulta.
- `lib/features` ja contem varias features com separacao parcial ou completa:
  `auth`, `admin`, `plans`, `parceiro`, `consultation`, `profile`,
  `subscription`, `referral`, `badge_progress`, `home`, `card`, `financeiro`.
- A pasta `test` existe, mas a cobertura ainda e inicial; o plano exige
  ampliar testes por camada e por feature.

### Camadas

- **Domain**: entities puras, enums, repository contracts e use cases. Nao deve
  importar Flutter, Supabase ou widgets.
- **Data**: models, mapeadores, datasources Supabase/mock, repository
  implementations e conversao de exceptions para failures.
- **Presentation**: pages, sections, widgets e BLoCs. Deve depender de use
  cases e entities, nunca diretamente de Supabase.
- **Core**: infraestrutura transversal e regras realmente compartilhadas.
  Evitar despejar regras especificas de feature em `core/services`.
- **Shared widgets**: componentes sem regra de negocio especifica e com API
  estavel.

### Componentes reutilizaveis

- `shared/widgets/buttons`: `PrimaryButton`, `SecondaryButton`, botoes de CTA
  com loading/disabled.
- `shared/widgets/forms`: inputs padronizados, field errors, masks wrappers e
  form section containers.
- `shared/widgets/feedback`: skeletons, empty states, error states, success
  feedback, unavailable states.
- `shared/widgets/cards`: cards genericos de informacao, metricas e beneficios.
- `features/*/presentation/widgets`: cards de plano, profissional, parceiro,
  badge, carteirinha, sorteio, cupom e secoes com copy/semantica da feature.
- `features/commercial_home/presentation/sections`: cada secao da home em
  widget proprio, com interface de dados pequena e testavel.

### Design system

Evoluir `AppTheme` para expor tokens nomeados:

- cores semanticas: primary, secondary, surface, border, text, muted, success,
  warning, error, info;
- texto: display, heading, title, body, label, caption;
- espacamentos: 4, 8, 12, 16, 24, 32, 40;
- radius: 8 para cards densos, 12/16 para componentes existentes, 24 apenas
  para inputs/botoes quando consistente;
- estados: hover/focus/pressed/disabled/loading/error/success;
- inputs e botoes: estilos unicos com variacoes por intencao;
- icones: SVG em `assets/icons`, com fallback e tamanho consistente.

### Home comercial mobile-first

Cada secao deve ser independente, com objetivo, dados, estados e Semantics:

- Header: navegacao curta, logo, entrar, CTA assinar; sticky apenas se nao
  prejudicar espaco mobile.
- Hero: proposta em 5 segundos, CTA primario, CTA contato, preco/beneficio e
  prova de confianca.
- Como funciona: 3 passos curtos para assinar, usar descontos e evoluir nivel.
- Beneficios: cards escaneaveis de descontos, parceiros, carteirinha,
  especialistas, sorteios e indicacoes.
- Planos e valores: cards com preco, recorrencia, beneficios, transparencia e
  CTA.
- Niveis: Bronze, Prata, Ouro, Diamante com desconto, limites e criterios.
- Especialistas: lista resumida com nome, especialidade, registro e CTA.
- Parceiros e exames: laboratorios/servicos, descontos, validacao e contato.
- Sorteios: regras, elegibilidade, premio, data e resultado quando houver.
- Prova de confianca: dados reais da clinica, localizacao, politicas,
  depoimentos reais quando disponiveis.
- FAQ: perguntas sobre regras, cancelamento, carencia, descontos e contato.
- CTA final: resumo do valor e acao sem friccao.
- Contato/rodape: WhatsApp, telefone, email, endereco/regiao, termos e
  privacidade.

### Supabase e dados dinamicos

- Comecar home com datasource local/static dentro da feature, mas por contrato
  de repository para permitir Supabase/CMS sem alterar UI.
- Consultas ao Supabase devem ficar em datasources.
- Repositories retornam `Either<Failure, Entity>`.
- Use cases encapsulam regra de permissao/negocio quando nao for puramente RLS.
- RLS deve separar dados publicos, dados do proprio cliente, dados de admin,
  dados financeiros/super admin e dados de parceiro.
- Dados sensiveis devem ser mascarados por papel e nunca depender apenas da UI.
- Acoes financeiras, sorteios, cupons e alteracao de roles precisam de
  validacao server-side e auditoria.

### Formularios

- Validacao local com `Validators` existentes e validacao server-side no
  datasource/use case.
- CPF/telefone/email com mensagens especificas e acessiveis.
- Loading por submit e bloqueio contra duplo envio.
- Feedback de sucesso/erro visivel e persistente o suficiente para leitura.
- Inputs com label, erro associado e Semantics quando necessario.
- Formulario dividido em etapas quando houver mais de 5-6 campos no mobile.

### Assets e imagens

- Manter imagens locais em `assets/images` e SVGs em `assets/icons`.
- Remover dependencias de assets remotos de design em producao.
- Usar imagens reais/profissionais para sujeitos inspecionaveis; fallback
  institucional quando nao houver foto.
- Padronizar tamanhos e proporcoes antes de entrar no app.
- Em imagens remotas futuras, usar URLs otimizadas, placeholder/skeleton,
  fallback e cache conforme plataforma.
- Toda imagem informativa deve ter contexto textual visivel ou Semantics.

### Performance

- Extrair widgets grandes em secoes pequenas e `const` quando possivel.
- Usar `BlocBuilder` com escopo minimo e `buildWhen` quando houver estado amplo.
- Evitar chamada Supabase em `build`; carregar via BLoC/use case.
- Usar paginacao ou carregamento progressivo para listas.
- Usar skeletons em vez de spinners globais.
- Evitar imagens enormes e SVGs complexos em areas repetidas.
- Medir rolagem e tempo de primeira tela em devices modestos.

### Acessibilidade

- Touch target minimo de 44x44.
- Contraste suficiente para texto, bordas funcionais e estados.
- Texto responsivo sem cortes com fonte maior.
- Labels em inputs e mensagens de erro claras.
- Semantics para carteirinha, QR, botoes icon-only, progresso e status.
- Nao depender apenas de cor para descontos, erros, niveis ou status.
- Ordem visual e de foco previsivel.

### SEO local

Flutter mobile nao resolve SEO. Para descoberta organica forte, criar uma
landing indexavel separada ou Flutter Web com limitacoes conhecidas e suporte
de metadados no host. Conteudo minimo:

- nome do negocio e proposta;
- cidade/regiao atendida;
- especialidades e servicos;
- planos e beneficios;
- parceiros/laboratorios;
- FAQ estruturado;
- telefone, WhatsApp, endereco/regiao e horarios;
- links para app/cadastro/contato;
- metadados de titulo, descricao, Open Graph e dados locais.

## Phase 0 Research Summary

Detalhes completos em [research.md](./research.md).

Decisoes principais:

- evoluir a arquitetura existente em vez de reestruturar o projeto;
- usar repositories mesmo para conteudo inicialmente estatico;
- separar home comercial de home autenticada se os objetivos divergirem;
- tratar SEO local como superficie web/indexavel dedicada quando for prioridade
  comercial;
- reforcar RLS, auditoria e validacao server-side para permissoes e acoes
  sensiveis;
- ampliar testes automatizados por camada e por feature.

## Phase 1 Design Summary

Artefatos gerados:

- [data-model.md](./data-model.md)
- [contracts/ui-contract.md](./contracts/ui-contract.md)
- [contracts/data-contract.md](./contracts/data-contract.md)
- [contracts/security-permissions-contract.md](./contracts/security-permissions-contract.md)
- [quickstart.md](./quickstart.md)

## Implementation Phases

### Fase 1: Fundacao de qualidade

- Consolidar tokens do design system em `AppTheme`.
- Reorganizar `shared/widgets` em subpastas sem quebrar imports publicos.
- Padronizar estados de loading, empty, error, success e unavailable.
- Criar checklist de acessibilidade e performance por PR/feature.
- Expandir helpers de teste e mocks por repository/use case.

### Fase 2: Home comercial

- Criar ou evoluir feature de home comercial com sections independentes.
- Iniciar com datasource local/static e repository.
- Modelar secoes: hero, como funciona, beneficios, planos, niveis,
  especialistas, parceiros, sorteios, prova de confianca, FAQ, contato.
- Conectar CTAs a cadastro, planos, WhatsApp, profissionais e parceiros.
- Validar mobile, conteudo realista, Semantics e performance.

### Fase 3: Dados dinamicos e Supabase

- Migrar secoes dinamicas para Supabase por repository.
- Adicionar cache leve onde fizer sentido.
- Garantir RLS por publico, cliente, admin, super admin/financeiro e parceiro.
- Registrar auditoria para acoes sensiveis.

### Fase 4: Fluxos principais

- Completar agendamento/contato de consultas.
- Completar pagamentos/regularizacao com gateway real.
- Completar sorteios com elegibilidade, execucao segura e notificacao.
- Fortalecer parceiros/laboratorios e validacao de desconto.
- Completar LGPD: consentimento, termos, exportacao e exclusao.

### Fase 5: Descoberta organica e operacao

- Definir superficie web/indexavel para SEO local.
- Publicar conteudo local real, FAQ, metadados e contatos.
- Criar painel ou CMS para conteudo editavel quando houver necessidade
  operacional.

## Risks & Mitigations

- **SEO em Flutter Web limitado**: mitigar com landing indexavel dedicada se SEO
  for canal importante.
- **Excesso de widgets em shared**: mitigar mantendo shared apenas para
  componentes genericos e estaveis.
- **Admin vendo dados sensiveis**: mitigar com RLS, views mascaradas e testes
  de permissao.
- **Conteudo estatico virar hardcode permanente**: mitigar com repository desde
  o inicio e entidades de conteudo.
- **Rebuilds e chamadas repetidas**: mitigar com BLoC, estados bem recortados e
  proibicao de chamadas remotas no `build`.
- **Pagamentos/sorteios/cupons fraudulentos**: mitigar com validacao server-side
  e audit log.

## Quality Checklist

- Home comunica proposta e CTA principal em ate 5 segundos.
- Conteudo realista, especifico e sem placeholders.
- Layout mobile-first sem rolagem horizontal, clipping ou controles pequenos.
- Todos os fluxos principais possuem loading, empty, error, success e
  unavailable states.
- Componentes reutilizaveis estao no lugar correto: shared quando genericos,
  feature quando especificos.
- Domain nao importa Flutter, Supabase ou widgets.
- Presentation nao acessa Supabase diretamente.
- Repositories retornam `Either<Failure, Entity>`.
- Dados sensiveis respeitam roles e RLS.
- Admin nao ve valores financeiros consolidados.
- Acoes sensiveis geram auditoria.
- Inputs possuem label, validacao e erro acessivel.
- Imagens possuem fallback e tamanho otimizado.
- CTAs importantes sao visiveis e testados no mobile.
- Testes unitarios, BLoC e widget cobrem regras e jornadas criticas.
- `flutter analyze` e `flutter test` passam antes da entrega.

## Complexity Tracking

Nenhuma violacao constitucional identificada. O uso de repositories e Clean
Architecture nao e complexidade adicional arbitraria: ja e o padrao do projeto
e permite migrar conteudo estatico para Supabase/CMS sem reescrever UI.
