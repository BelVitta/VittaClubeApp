# Research: Aplicativo de Cartao Fidelidade em Saude

## Decision: Evoluir a arquitetura atual, sem reescrita

**Rationale**: A codebase ja possui `lib/core`, `lib/shared` e `lib/features`
com Clean Architecture parcial ou completa. Features como `auth`, `admin`,
`parceiro`, `plans`, `consultation`, `profile`, `subscription`, `referral` e
`badge_progress` ja usam ou apontam para `domain/data/presentation`, BLoC,
repositories, datasources e use cases. Reescrever criaria risco sem ganho.

**Alternatives considered**:

- Recriar o app com arquitetura nova: rejeitado por custo e risco.
- Manter tudo como widgets diretos: rejeitado por dificultar Supabase, testes e
  evolucao para CMS/painel.

## Decision: Criar repository mesmo para conteudo inicialmente estatico

**Rationale**: A home comercial comecara com conteudo estatico, mas a
especificacao exige crescimento para Supabase, CMS ou painel. Repository e
datasource local permitem trocar a origem de dados sem refatorar secoes e UI.

**Alternatives considered**:

- Hardcode direto nos widgets: rapido no inicio, mas cria divida tecnica e
  dificulta testes.
- Buscar tudo no Supabase desde a primeira entrega: aumenta dependencia e
  complexidade antes de validar layout/conteudo.

## Decision: Separar home comercial de home autenticada quando os objetivos divergirem

**Rationale**: A home autenticada atual mostra status do plano, consultas e
acoes rapidas. A home comercial precisa vender, construir confianca e gerar
contato. Se ambas dividirem a mesma page, a intencao de produto fica confusa.
Uma feature `commercial_home` ou subarea isolada em `home` reduz acoplamento.

**Alternatives considered**:

- Misturar tudo em `HomePage`: rejeitado por misturar aquisicao e uso do app.
- Criar outro app apenas para landing: aceitavel so se SEO local forte exigir
  stack web dedicada.

## Decision: Flutter mobile-first como principal; superficie web dedicada para SEO forte

**Rationale**: Flutter e adequado para app mobile e painel operacional, mas SEO
organico exige HTML semantico, metadados e indexacao previsivel. Se SEO local
for canal comercial relevante, a melhor decisao e uma landing web indexavel
integrada aos mesmos dados comerciais.

**Alternatives considered**:

- Depender apenas de Flutter Web para SEO: possivel para presenca simples, mas
  limitado para descoberta organica forte.
- Ignorar SEO: rejeitado pela especificacao e constituicao.

## Decision: Manter BLoC, GetIt e Either como padrao

**Rationale**: O projeto ja usa `flutter_bloc`, `get_it` e `dartz`. Manter esse
padrao reduz mistura de estilos, facilita testes com `bloc_test`/`mocktail` e
mantem tratamento de erro consistente.

**Alternatives considered**:

- Introduzir Riverpod/Provider agora: rejeitado por adicionar dois padroes de
  estado no mesmo app.
- Retornar exceptions diretamente: rejeitado por quebrar padrao de failures e
  tornar UI mais fragil.

## Decision: Supabase protegido por RLS, views e validacao server-side

**Rationale**: O app trata dados de saude, dados pessoais, pagamentos,
permissoes, sorteios e cupons. A UI nao pode ser o limite de seguranca. RLS,
views mascaradas, RPCs/validacoes server-side e audit log sao obrigatorios
para roles `user`, `admin`, `financeiro/super_admin` e `parceiro`.

**Alternatives considered**:

- Filtrar tudo no cliente: rejeitado por risco de vazamento e fraude.
- Dar ao admin acesso amplo: rejeitado por risco financeiro e LGPD.

## Decision: Testes automatizados por camada e jornada critica

**Rationale**: A constituicao torna testes obrigatorios. Unit tests cobrem
regras de desconto, elegibilidade, validacao e permissoes; BLoC tests cobrem
estados; widget tests cobrem UI, CTAs e estados; testes de permissao validam
seguranca de acesso.

**Alternatives considered**:

- Testar apenas manualmente: rejeitado por risco de regressao.
- Testar somente widgets: insuficiente para regras e roles.

## Decision: Design system incremental em `AppTheme`

**Rationale**: `AppTheme` ja centraliza cores e tipografia. Evoluir com tokens
de espacamento, radius, botoes, inputs e estados cria consistencia sem trocar
o tema inteiro.

**Alternatives considered**:

- Criar pacote/design system separado agora: prematuro.
- Deixar estilos em cada widget: rejeitado por inconsistencia visual e custo de
  manutencao.
