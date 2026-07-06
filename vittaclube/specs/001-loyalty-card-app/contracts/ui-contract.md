# UI Contract: Vitta Clube

## Global UI Rules

- Toda tela deve ser mobile-first.
- Toda tela deve possuir estados de loading, empty, error, success e
  unavailable quando houver dados ou acao remota.
- Nenhuma interface pode exibir lorem ipsum, texto generico ou dado inventado
  sem identificacao.
- CTA principal deve ser visualmente evidente nas telas comerciais e fluxos de
  conversao.
- Botoes icon-only precisam de tooltip ou Semantics label.
- Acoes destrutivas ou sensiveis precisam de confirmacao.

## Commercial Home Contract

### Header

**Inputs**: logo, navigationLinks, loginCta, primaryCta.

**Required behavior**:

- exibir logo e CTA principal no mobile;
- reduzir links em menu/atalhos quando nao couber;
- manter foco navegavel.

### Hero

**Inputs**: headline, subtitle, primaryCta, secondaryCta, trustProof,
priceHint, heroImage.

**Acceptance**:

- proposta entendida em ate 5 segundos;
- CTA principal visivel sem rolagem;
- contato acessivel em ate dois toques.

### Plan Cards

**Inputs**: planName, price, billingCycle, benefits, transparencyNote, cta.

**Acceptance**:

- preco e recorrencia legiveis;
- beneficios especificos;
- CTA acionavel;
- estado sem planos orienta contato.

### Loyalty Levels

**Inputs**: level, discountPercent, consultationLimit, requirements, benefits.

**Acceptance**:

- nao depende apenas de cor para diferenciar niveis;
- explica como evoluir;
- mostra desconto e limite.

### Professionals

**Inputs**: name, specialty, registry, photo, availability, contactAction.

**Acceptance**:

- registro profissional visivel quando aplicavel;
- foto tem fallback;
- contato/agendamento tem texto claro.

### Partners

**Inputs**: name, category, services, discount, validationMethod, contact.

**Acceptance**:

- cliente entende como validar desconto;
- valores ausentes geram orientacao de contato;
- parceiro inativo nao aparece como disponivel.

### FAQ

**Inputs**: question, answer, category.

**Acceptance**:

- cobre regras de plano, carencia, descontos, cancelamento, parceiros,
  sorteios e contato;
- acordeoes possuem estado acessivel.

## Authenticated Home Contract

**Required content**:

- saudacao;
- status do plano;
- nivel e progresso;
- carteirinha/QR;
- acoes rapidas: planos, profissionais, parceiros, pagamentos, beneficios;
- historico ou estado vazio de consultas.

**Acceptance**:

- cliente localiza nivel, desconto e carteirinha em ate 15 segundos;
- inadimplente ve aviso claro e caminho de regularizacao;
- periodo de carencia explica data de liberacao.

## Admin Contract

**Required behavior**:

- admin pode operar cadastros e consultas;
- admin nao ve relatorios financeiros consolidados;
- admin ve pagamento apenas como status operacional;
- campos sensiveis devem ser mascarados quando exibidos.

## Super Admin Contract

**Required behavior**:

- super admin gerencia roles, planos, precos, parceiros, sorteios, cupons e
  relatorios;
- acoes criticas possuem confirmacao e audit log;
- relatorios financeiros nao aparecem para admin comum.

## Accessibility Contract

- touch target minimo: 44x44;
- contraste suficiente em textos e estados;
- inputs com label persistente ou associado;
- mensagens de erro em texto, nao apenas cor;
- Semantics para QR, progresso, status, botoes icon-only e imagens
  informativas;
- fonte maior nao pode quebrar fluxo principal.

## Performance Contract

- nenhum acesso remoto no metodo `build`;
- listas potencialmente longas precisam de listagem eficiente;
- imagens remotas precisam de skeleton/fallback;
- widgets grandes devem ser separados em componentes menores;
- BLoCs devem carregar dados por evento explicito.
