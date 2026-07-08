# Research: Pagamentos e Assinatura Pix Automático

## Decision: Usar Woovi Pix Automático via Subscriptions

**Rationale**: A feature exige Pix Automático oficial com autorização prévia do pagador e cobranças recorrentes. A Woovi expõe endpoints de subscription para criação, consulta e cancelamento, com produção em `https://api.woovi.com` e sandbox em `https://api.woovi-sandbox.com`. O prompt fixa `POST /api/v1/subscriptions`, `GET /api/v1/subscriptions/{id}` e `DELETE /api/v1/subscriptions/{id}`.

**Alternatives considered**:

- Pix QR avulso mensal: rejeitado porque exigiria ação mensal do usuário e aumentaria churn involuntário.
- Cartão de crédito: fora de escopo e será tratado por outro provedor.
- Cobrança manual pelo operador: rejeitada por não escalar e não atender MRR recorrente.

## Decision: Jornadas e estados devem respeitar autorização antes de cobrança

**Rationale**: Pix Automático depende de autorização do pagador no banco. O app deve criar a autorização, entregar `paymentLinkUrl` e aguardar confirmação real antes de ativar acesso. O retorno do banco não é confirmação suficiente.

**Alternatives considered**:

- Ativar ao abrir o link: rejeitado por liberar acesso sem consentimento/pagamento confirmado.
- Ativar no retorno ao app: rejeitado porque o usuário pode abandonar ou o banco ainda não ter confirmado.

## Decision: Usar `PAYMENT_ON_APPROVAL` e valor fixo de R$34,90

**Rationale**: A especificação exige que a primeira mensalidade seja cobrada no momento da aprovação da autorização, liberando acesso imediatamente após confirmação. O valor é fixo nesta fase, então `value = 3490` centavos.

**Alternatives considered**:

- Autorização sem primeira cobrança: rejeitada porque atrasaria a ativação e criaria estado sem receita.
- Valores por plano: rejeitado porque a fase atual tem apenas assinatura fixa.

## Decision: Retentativa `THREE_RETRIES_7_DAYS`

**Rationale**: O prompt exige até 3 tentativas em até 7 dias, e a comunicação pública da Woovi/Pix Automático descreve retentativa de até 3 vezes em até 7 dias corridos. O sistema marca pendência na primeira falha e bloqueia apenas após expiração da janela.

**Alternatives considered**:

- Bloquear na primeira falha: rejeitado porque aumenta churn involuntário.
- Manter acesso indefinidamente: rejeitado porque compromete receita.

## Decision: Supabase Edge Functions como única fronteira Woovi

**Rationale**: O App ID, webhook secret, HMAC e chamadas de reconciliação não podem ficar no mobile. Edge Functions permitem backend-only com variáveis de ambiente separadas por sandbox/produção.

**Alternatives considered**:

- Chamada Woovi direto do Flutter: rejeitada por expor segredo e permitir fraude.
- Backend externo separado: rejeitado por aumentar infraestrutura sem necessidade nesta fase.

## Decision: Postgres como fonte de verdade do acesso

**Rationale**: Webhooks podem atrasar, duplicar ou chegar fora de ordem. O app deve ler o status consolidado de `subscriptions` no Supabase, não consultar a Woovi diretamente nem inferir estado por URL aberta.

**Alternatives considered**:

- Fonte de verdade no app: rejeitada por insegurança e inconsistência.
- Fonte de verdade somente na Woovi: rejeitada porque o app precisa de status rápido, RLS e integração com dependentes/QR.

## Decision: Deduplicação por evento recebido

**Rationale**: Webhooks são reentregues em caso de falha ou timeout. Cada evento deve ser gravado com ID único antes de alterar assinatura/cobrança; evento duplicado retorna sucesso sem novo efeito.

**Alternatives considered**:

- Deduplicar por `correlationID`: insuficiente porque o mesmo contrato gera múltiplas cobranças e tentativas.
- Processar sempre: rejeitado por risco de dupla notificação e dupla alteração de período.

## Decision: Validar webhook por HMAC antes de processar

**Rationale**: A Edge Function deve rejeitar payload não assinado ou assinatura inválida antes de gravar evento, evitando falsificação de pagamento/cancelamento.

**Alternatives considered**:

- Apenas obscuridade da URL: rejeitada por ser insuficiente para eventos financeiros.
- Validação depois da persistência: rejeitada porque armazenaria eventos potencialmente falsos como legítimos.

## Decision: Mapear eventos do prompt e eventos Pix Automático oficiais

**Rationale**: O prompt lista eventos `OPENPIX:SUBSCRIPTION_*` e `OPENPIX:CHARGE_*`. A documentação atual da Woovi também lista eventos específicos de Pix Automático como `PIX_AUTOMATIC_APPROVED`, `PIX_AUTOMATIC_REJECTED`, `PIX_AUTOMATIC_COBR_CREATED`, `PIX_AUTOMATIC_COBR_REJECTED`, `PIX_AUTOMATIC_COBR_TRY_REJECTED`, `PIX_AUTOMATIC_COBR_TRY_REQUESTED` e `PIX_AUTOMATIC_COBR_COMPLETED`. O contrato deve aceitar ambos os grupos quando semanticamente equivalentes.

**Alternatives considered**:

- Aceitar só eventos do prompt: arriscado se a conta Woovi emitir os nomes oficiais atuais.
- Aceitar qualquer evento: rejeitado por segurança e ambiguidade.

## Decision: Reconciliação por consulta de subscription na Woovi

**Rationale**: Se webhook se perder, atrasar ou chegar fora de ordem, uma Edge Function de reconciliação consulta `GET /api/v1/subscriptions/{id}` usando `correlationID`/ID e atualiza status local de forma idempotente.

**Alternatives considered**:

- Confiar apenas em webhook: rejeitado por risco operacional.
- Reconciliar a cada abertura de tela: rejeitado por latência e excesso de chamadas.

## Decision: RLS permite usuário ler apenas sua assinatura

**Rationale**: Dados de assinatura, cobrança e status financeiro são sensíveis. Usuário comum só lê sua própria assinatura/cobranças; operadores têm políticas separadas conforme roles existentes.

**Alternatives considered**:

- Liberar leitura ampla para facilitar debug: rejeitado por privacidade/LGPD.
- Bloquear leitura do usuário e usar apenas function: possível, mas piora UX e aumenta chamadas; leitura própria com RLS é suficiente.
