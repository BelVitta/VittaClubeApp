# Feature Specification: Pagamentos e Assinatura Pix Automático

**Feature Branch**: `002-pix-auto-subscription`

**Created**: 2026-06-02

**Status**: Draft

**Input**: User description: "Construa o sistema de pagamentos e assinatura do VittaClube, um aplicativo mobile de clube de descontos em saúde. O acesso ao app é exclusivamente pago, via assinatura mensal recorrente de R$34,90 por Pix Automático, sem plano gratuito e sem teste grátis. A feature cobre ativação, cobrança recorrente, recuperação de falhas, cancelamento, controle de acesso, sandbox, idempotência e bloqueio de QR quando inadimplente."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ativar assinatura recorrente (Priority: P1)

Um novo usuário decide assinar o VittaClube, entende claramente que autorizará uma cobrança recorrente automática de R$34,90 por mês, aprova a autorização no aplicativo do banco e tem o acesso liberado automaticamente quando a autorização e a primeira cobrança são confirmadas.

**Why this priority**: Sem ativação paga não há acesso ao produto nem receita recorrente. Esta jornada é o principal ponto de conversão e precisa evitar confusão entre pagamento único e recorrência.

**Independent Test**: Pode ser testada iniciando uma assinatura em ambiente de teste, simulando aprovação no banco, retorno ao app, confirmação assíncrona e liberação do acesso.

**Business Outcome**: Geração de MRR com conversão paga e redução de dúvidas/suporte sobre a natureza recorrente da cobrança.

**Trust/Conversion Requirement**: A tela anterior ao redirecionamento bancário deve exibir preço, recorrência mensal, ausência de plano gratuito/teste grátis, saída momentânea para o app do banco, retorno ao VittaClube e direito de cancelamento pelo banco.

**Acceptance Scenarios**:

1. **Given** um usuário autenticado sem assinatura ativa, **When** ele escolhe assinar, lê a explicação e confirma, **Then** o sistema cria uma solicitação de autorização recorrente e direciona o usuário para aprovar no banco.
2. **Given** uma autorização aprovada pelo banco com primeira cobrança paga, **When** o app recebe a confirmação, **Then** a assinatura fica ativa imediatamente e o usuário acessa o app.
3. **Given** o usuário retorna do banco antes da confirmação final, **When** o app ainda não recebeu o estado definitivo, **Then** o app mostra "aguardando confirmação do seu banco" e não assume aprovação.
4. **Given** uma autorização recusada ou abandonada, **When** o estado final é recebido ou consultado, **Then** o app explica que a autorização não foi concluída e oferece tentar novamente.

---

### User Story 2 - Cobrar mensalidade recorrente automaticamente (Priority: P1)

Um assinante ativo tem a mensalidade de R$34,90 cobrada automaticamente a cada ciclo, no mesmo dia definido na assinatura, sem precisar realizar um novo pagamento manual a cada mês.

**Why this priority**: A cobrança automática é a base para reduzir churn involuntário e sustentar a receita recorrente do produto.

**Independent Test**: Pode ser testada com uma assinatura ativa em sandbox, avançando para o ciclo seguinte e simulando cobrança mensal paga sem ação do usuário.

**Business Outcome**: Manutenção do MRR com menor dependência de lembretes manuais ou ações repetidas do cliente.

**Trust/Conversion Requirement**: O usuário deve conseguir ver status ativo, valor mensal, próximo vencimento e informação de que a cobrança será automática pelo banco autorizado.

**Acceptance Scenarios**:

1. **Given** uma assinatura ativa, **When** chega o próximo ciclo mensal, **Then** uma cobrança de R$34,90 é preparada e enviada para débito automático.
2. **Given** uma assinatura criada em dia 31, **When** o mês seguinte não tem dia 31, **Then** a cobrança ocorre no último dia do mês.
3. **Given** uma cobrança recorrente paga, **When** o pagamento é confirmado, **Then** a assinatura permanece ativa e o histórico registra a mensalidade paga.

---

### User Story 3 - Recuperar cobrança com falha (Priority: P1)

Quando uma cobrança mensal falha, o titular é avisado imediatamente e marcado como pagamento pendente, mas o sistema permite recuperação automática por até 7 dias com até 3 tentativas antes de bloquear o acesso.

**Why this priority**: Recuperar falhas de pagamento reduz churn involuntário sem exigir que o usuário faça um pagamento manual a cada falha temporária.

**Independent Test**: Pode ser testada simulando falha inicial, notificação, tentativas automáticas, recuperação bem-sucedida e expiração sem pagamento.

**Business Outcome**: Redução de perda de receita por falhas temporárias, como saldo insuficiente no dia da cobrança.

**Trust/Conversion Requirement**: As mensagens devem explicar o que aconteceu, que o sistema ainda tentará cobrar automaticamente, qual é o prazo de recuperação e quando o acesso será bloqueado.

**Acceptance Scenarios**:

1. **Given** uma cobrança mensal falha, **When** a primeira falha é confirmada, **Then** o titular fica com pagamento pendente em recuperação e recebe uma notificação clara.
2. **Given** uma cobrança em recuperação, **When** uma retentativa dentro de até 7 dias é paga, **Then** o status pendente é removido automaticamente e o acesso continua liberado.
3. **Given** uma cobrança em recuperação, **When** todas as tentativas falham ou a janela de 7 dias termina sem pagamento, **Then** a assinatura fica inadimplente bloqueada e o acesso do titular e dependentes é bloqueado.

---

### User Story 4 - Bloquear acesso e QR quando inadimplente (Priority: P1)

Um titular inadimplente ou cancelado não consegue usar o clube, gerar ou validar QR de benefício, nem liberar uso para dependentes, e vê uma chamada clara para restaurar a conta.

**Why this priority**: O produto é exclusivamente pago; permitir uso inadimplente compromete receita e regras de negócio.

**Independent Test**: Pode ser testada colocando uma assinatura em estado não pago/cancelado e tentando abrir áreas protegidas, usar QR e acessar dependentes.

**Business Outcome**: Proteção da receita e coerência do benefício pago.

**Trust/Conversion Requirement**: O modal de restauração deve explicar o motivo do bloqueio, o valor da assinatura, o caminho para regularizar e o que acontece após a regularização.

**Acceptance Scenarios**:

1. **Given** um titular com assinatura definitivamente não paga, **When** ele tenta acessar QR, benefícios, agendamentos ou dependentes, **Then** o sistema bloqueia a ação e mostra modal para restaurar a conta.
2. **Given** um dependente vinculado a titular bloqueado, **When** tenta usar benefício ou QR, **Then** o acesso é bloqueado pela assinatura do titular.
3. **Given** uma conta bloqueada por inadimplência, **When** o pagamento é regularizado, **Then** o acesso é restaurado automaticamente após confirmação real do pagamento.

---

### User Story 5 - Refletir cancelamento da recorrência (Priority: P2)

O cliente cancela a recorrência pelo aplicativo do banco ou um operador cancela a assinatura, e o VittaClube reflete corretamente o encerramento sem confundir o usuário.

**Why this priority**: Cancelamento claro reduz atrito, reclamações e risco regulatório, mantendo controle de acesso correto.

**Independent Test**: Pode ser testada simulando cancelamento vindo do banco e cancelamento feito por operador, verificando comunicação e bloqueio ao fim do ciclo pago.

**Business Outcome**: Redução de suporte e prevenção de uso indevido após encerramento.

**Trust/Conversion Requirement**: O usuário deve ver status de cancelamento, data de fim do ciclo pago e explicação objetiva de como reativar.

**Acceptance Scenarios**:

1. **Given** um cancelamento feito no banco, **When** o sistema recebe a confirmação, **Then** a assinatura é marcada como cancelada e o acesso permanece até o fim do ciclo já pago.
2. **Given** o ciclo pago terminou após cancelamento, **When** o usuário tenta acessar áreas protegidas, **Then** o acesso é bloqueado e o app oferece reativação.
3. **Given** um operador autorizado cancela uma assinatura, **When** a ação é concluída, **Then** a assinatura reflete cancelamento e o titular é informado.

---

### User Story 6 - Validar cenários em sandbox (Priority: P2)

Equipe operacional e QA conseguem demonstrar toda a jornada de pagamento recorrente em ambiente de teste, sem conta bancária real.

**Why this priority**: Pagamento recorrente é financeiro e assíncrono; a feature só pode ir para produção se todos os estados críticos forem demonstráveis antes.

**Independent Test**: Pode ser testada executando cenários sandbox de autorização aprovada/recusada, primeira cobrança paga, recorrência paga, falha recuperada e falha expirada.

**Business Outcome**: Redução de risco operacional e de incidentes financeiros em produção.

**Trust/Conversion Requirement**: O ambiente de teste deve deixar claro que não há cobrança real e deve permitir simular estados sem afetar clientes reais.

**Acceptance Scenarios**:

1. **Given** ambiente de teste ativo, **When** QA executa os cenários obrigatórios, **Then** todos os estados de assinatura, cobrança e acesso podem ser demonstrados sem conta bancária real.
2. **Given** ambiente de produção ativo, **When** um usuário real assina, **Then** a experiência não exibe dados ou textos de sandbox.

---

### Edge Cases

- O usuário fecha o VittaClube ou o app do banco durante a aprovação; ao voltar, o app deve consultar/refletir o estado real e permitir continuar ou tentar novamente.
- O mesmo evento financeiro chega mais de uma vez; o sistema não pode liberar acesso, criar cobrança, alterar status ou notificar em duplicidade.
- Um evento financeiro chega fora de ordem; o estado final da assinatura deve permanecer coerente com o ciclo, pagamento e cancelamento mais recentes.
- A confirmação de pagamento demora; o app deve mostrar estado de espera com opção de atualizar, sem prometer acesso antes da confirmação.
- A cobrança falha no primeiro dia e depois é paga em retentativa; o app deve remover pendência e evitar notificação repetida da falha antiga.
- A cobrança falha em todas as tentativas; titular, dependentes e QR devem ser bloqueados após a janela de recuperação.
- O cliente cancela a recorrência no banco no meio do ciclo pago; o acesso deve continuar até o fim do período já pago.
- O cliente tenta cancelar ou reativar quando há cobrança pendente; o app deve explicar o estado atual e o caminho válido.
- Dia de cobrança inexistente em mês curto deve usar o último dia do mês.
- Conexão lenta, retorno incompleto do banco ou indisponibilidade temporária do provedor devem exibir estados de espera/erro sem criar duplicidade.
- Usuário inadimplente tenta abrir QR já gerado anteriormente; o QR não pode ser utilizado enquanto a assinatura estiver bloqueada.
- Operador tenta cancelar assinatura de usuário inexistente ou já cancelado; o sistema deve evitar ação duplicada e explicar o estado atual.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST exigir assinatura paga ativa para acesso ao VittaClube; não deve existir plano gratuito nem período de teste gratuito para esta feature.
- **FR-002**: O sistema MUST oferecer assinatura mensal recorrente com valor fixo de R$34,90.
- **FR-003**: O sistema MUST apresentar, antes da autorização, uma explicação clara de que o usuário autorizará cobrança recorrente automática mensal, não pagamento único.
- **FR-004**: O sistema MUST informar antes da autorização que a aprovação ocorre no aplicativo do banco e que o usuário sairá momentaneamente do VittaClube.
- **FR-005**: O sistema MUST informar antes da autorização que o cliente pode cancelar a recorrência pelo aplicativo do banco.
- **FR-006**: O sistema MUST solicitar autorização inicial de Pix Automático somente após o usuário confirmar que entendeu as condições.
- **FR-007**: O sistema MUST tratar a aprovação bancária como assíncrona e nunca assumir aprovação apenas pelo retorno do usuário ao app.
- **FR-008**: O sistema MUST exibir estado "aguardando confirmação do seu banco" enquanto a autorização ainda não tiver confirmação final.
- **FR-009**: O sistema MUST ativar a assinatura imediatamente quando a autorização for aprovada e a primeira mensalidade for paga.
- **FR-010**: O sistema MUST explicar autorização recusada, expirada ou abandonada e permitir nova tentativa de assinatura.
- **FR-011**: O sistema MUST preparar cobrança mensal automática a cada ciclo no mesmo dia definido na criação da assinatura.
- **FR-012**: O sistema MUST cobrar no último dia do mês quando o dia original do ciclo não existir no mês corrente.
- **FR-013**: O sistema MUST registrar e exibir para o usuário o status da assinatura, valor mensal, data do próximo ciclo e situação de pagamento.
- **FR-014**: O sistema MUST marcar o titular como pagamento pendente em recuperação imediatamente após a primeira falha de cobrança mensal.
- **FR-015**: O sistema MUST notificar o titular na primeira falha de cobrança com mensagem clara sobre falha, retentativas automáticas e prazo de regularização.
- **FR-016**: O sistema MUST considerar uma janela de recuperação de até 7 dias com até 3 tentativas automáticas de cobrança.
- **FR-017**: O sistema MUST manter o acesso liberado durante a janela de recuperação, mas com aviso persistente de pagamento pendente.
- **FR-018**: O sistema MUST remover automaticamente o status pendente quando uma retentativa dentro da janela for paga.
- **FR-019**: O sistema MUST bloquear o acesso quando a cobrança expirar sem pagamento após a janela de recuperação.
- **FR-020**: O sistema MUST bloquear titular e dependentes vinculados quando a assinatura do titular estiver definitivamente não paga ou cancelada sem ciclo pago vigente.
- **FR-021**: O sistema MUST impedir geração, exibição útil ou validação de QR de benefício quando a assinatura do titular estiver bloqueada por inadimplência ou encerramento.
- **FR-022**: O sistema MUST exibir modal de restauração de conta quando usuário bloqueado tentar acessar áreas protegidas, QR, benefícios, agendamento ou dependentes.
- **FR-023**: O modal de restauração MUST explicar motivo do bloqueio, valor mensal, ação principal para regularizar/reativar e efeito esperado após confirmação.
- **FR-024**: O sistema MUST refletir cancelamento da recorrência feito no aplicativo do banco.
- **FR-025**: O sistema MUST permitir cancelamento de assinatura por operador autorizado.
- **FR-026**: O sistema MUST manter acesso até o fim do ciclo pago quando a recorrência for cancelada após uma mensalidade já paga.
- **FR-027**: O sistema MUST bloquear acesso ao fim do ciclo pago quando uma assinatura cancelada não tiver nova regularização.
- **FR-028**: O sistema MUST disponibilizar interfaces necessárias para usuário e operador acompanharem, restaurarem ou cancelarem assinatura; se alguma superfície ainda não existir no produto, ela deve ser especificada antes da implementação.
- **FR-029**: O sistema MUST disponibilizar ambiente de teste que permita simular autorização aprovada, autorização recusada, primeira cobrança paga, recorrência paga, falha recuperada e falha expirada sem conta bancária real.
- **FR-030**: O sistema MUST separar claramente experiência de teste e produção, impedindo que usuários reais vejam dados ou textos de sandbox.
- **FR-031**: O sistema MUST tratar eventos financeiros assíncronos de forma idempotente, sem efeitos duplicados ao receber o mesmo evento mais de uma vez.
- **FR-032**: O sistema MUST permitir reconciliação do estado da assinatura com o provedor quando houver perda, atraso ou inconsistência de eventos.
- **FR-033**: O sistema MUST manter o estado da assinatura no VittaClube como fonte de verdade para liberar ou bloquear acesso no app.
- **FR-034**: O sistema MUST evitar notificações repetidas para o mesmo evento de falha, recuperação, cancelamento ou bloqueio.
- **FR-035**: O sistema MUST registrar histórico compreensível de autorizações, cobranças, falhas, recuperações, cancelamentos e bloqueios para suporte operacional.
- **FR-UX-001**: System MUST provide mobile-first layouts with visible primary CTA, readable hierarchy, and no clipped or overlapping content.
- **FR-UX-002**: System MUST provide explicit loading, empty, error, success, and unavailable states for every user-facing flow.
- **FR-CONTENT-001**: System MUST use specific, realistic clinic and loyalty-card content; placeholder or generic copy is not acceptable.
- **FR-A11Y-001**: System MUST meet accessibility requirements for semantic structure, focus, contrast, readable text, and assistive technology support.
- **FR-SEO-001**: Public web content MUST include local SEO structure, semantic headings, metadata, and real clinic contact/location information where applicable.

### Key Entities *(include if feature involves data)*

- **Assinatura**: Representa o direito recorrente de acesso do titular ao VittaClube. Inclui titular, valor mensal, status, data de início, dia do ciclo, próximo vencimento, fim do ciclo pago e situação de cancelamento.
- **Autorização de Pix Automático**: Representa a autorização recorrente dada pelo cliente no aplicativo do banco. Inclui estado de aprovação, validade, vínculo com assinatura e motivo de recusa/cancelamento quando aplicável.
- **Cobrança Mensal**: Representa uma mensalidade de R$34,90 dentro de um ciclo. Inclui vencimento, estado de pagamento, tentativas, janela de recuperação e resultado final.
- **Tentativa de Cobrança**: Representa cada tentativa automática de débito durante a cobrança mensal, incluindo sucesso, falha e motivo informado.
- **Evento Financeiro**: Representa uma confirmação assíncrona de autorização, pagamento, falha, recuperação, expiração ou cancelamento recebida do provedor.
- **Bloqueio de Acesso**: Representa o estado em que titular e dependentes ficam impedidos de usar benefícios, QR e áreas protegidas.
- **Notificação de Pagamento**: Representa mensagens enviadas ao titular sobre falha, recuperação, bloqueio, cancelamento ou reativação.
- **Ação Operacional**: Representa ações feitas por operador autorizado, como cancelamento, consulta de histórico e apoio à regularização.

## Product, UX & Content Requirements *(mandatory)*

- **Primary CTA**: "Assinar por R$34,90/mês" deve aparecer na tela de paywall/ativação e levar à tela explicativa antes da autorização bancária. Em conta bloqueada, o CTA principal deve ser "Restaurar minha conta" ou "Regularizar assinatura".
- **Secondary CTAs**: "Entender como funciona", "Tentar novamente", "Atualizar status", "Ver histórico da assinatura", "Falar com suporte" e "Voltar ao app" devem aparecer conforme o estado da jornada.
- **Trust Proof**: A jornada deve exibir valor fixo, recorrência mensal, ausência de teste grátis, cancelamento pelo banco, explicação de Pix Automático, segurança da aprovação no banco e dados reais do VittaClube/clinica quando disponíveis.
- **First-Screen Requirement**: Antes de qualquer redirecionamento ao banco, a primeira tela deve comunicar em poucos segundos: preço, recorrência mensal automática, aprovação no banco, liberação após confirmação e possibilidade de cancelamento.
- **Mobile-First Behavior**: Todo fluxo deve funcionar em telas pequenas com CTA visível, texto legível, botões com área de toque confortável, estados de espera claros e nenhum controle encoberto por modal, teclado ou barra inferior.
- **Accessibility Requirements**: Botões, modais, status de pagamento, mensagens de erro e campos devem ter labels compreensíveis, contraste suficiente, foco previsível, leitura por tecnologia assistiva e não depender apenas de cor.
- **Content Standard**: Textos devem ser diretos, financeiros e confiáveis, sem linguagem vaga como "plano especial" ou "benefício incrível" sem explicar valor, recorrência e consequência. Placeholder, lorem ipsum e mensagens genéricas de erro não são aceitáveis.
- **SEO Local Requirements**: Não se aplica à jornada mobile autenticada de pagamento. Se houver paywall público ou página web de assinatura, ela deve conter nome do VittaClube, proposta de clube de descontos em saúde, região atendida, dados institucionais, FAQ de assinatura e metadados locais.
- **Performance Requirement**: O usuário deve ver feedback imediato ao iniciar autorização, retornar do banco, atualizar status, restaurar conta ou abrir modal de bloqueio; estados assíncronos devem evitar telas congeladas ou repetição de ações.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% dos usuários em sandbox conseguem concluir a ativação aprovada com liberação automática de acesso em até 2 minutos após a confirmação simulada.
- **SC-002**: 100% das ativações aprovadas com primeira mensalidade paga resultam em assinatura ativa e acesso liberado sem intervenção manual.
- **SC-003**: 100% dos retornos do banco sem confirmação final exibem estado de espera e não liberam acesso indevidamente.
- **SC-004**: 100% das cobranças mensais pagas em sandbox preservam acesso ativo no ciclo seguinte sem ação manual do usuário.
- **SC-005**: 100% das primeiras falhas de cobrança marcam pagamento pendente e geram notificação única ao titular.
- **SC-006**: 100% das cobranças recuperadas dentro de até 7 dias removem pendência automaticamente e mantêm acesso liberado.
- **SC-007**: 100% das cobranças expiradas após janela de recuperação bloqueiam titular, dependentes e QR até regularização.
- **SC-008**: 100% das tentativas de usar QR por titular inadimplente ou cancelado são bloqueadas e exibem modal de restauração.
- **SC-009**: 100% dos eventos financeiros duplicados usados em testes não geram cobrança, notificação, liberação ou bloqueio duplicado.
- **SC-010**: QA consegue demonstrar em sandbox todos os cenários obrigatórios: autorização aprovada, autorização recusada, primeira cobrança paga, recorrência paga, falha recuperada e falha expirada.
- **SC-011**: Usuários conseguem identificar em até 5 segundos que a assinatura custa R$34,90 por mês e é recorrente automática.
- **SC-012**: O fluxo principal de assinatura completa em mobile sem rolagem horizontal, texto cortado, controles sobrepostos ou modal inacessível.

## Assumptions

- O VittaClube já possui autenticação de usuário; esta feature define apenas pagamento, assinatura e controle de acesso relacionado.
- A assinatura é sempre individual do titular e o valor permanece fixo em R$34,90 nesta fase.
- Dependentes já existem em outra feature; aqui eles só herdam o direito de acesso do titular.
- Durante a janela de recuperação de até 7 dias, o acesso permanece liberado com aviso persistente; o bloqueio ocorre apenas após expiração da recuperação ou cancelamento sem ciclo pago vigente.
- O cancelamento feito no banco encerra novas cobranças, mas não remove acesso já pago até o fim do ciclo vigente.
- Notificações podem aparecer dentro do app e, quando houver canal disponível, também por canais externos definidos pelo produto.
- O ambiente de teste deve simular estados financeiros sem movimentar dinheiro real.
- Pagamento por cartão de crédito, cobrança adicional por dependente e alterações de preço estão fora do escopo desta especificação.
