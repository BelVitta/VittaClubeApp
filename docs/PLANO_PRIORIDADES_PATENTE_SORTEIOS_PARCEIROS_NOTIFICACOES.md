# Plano de execução — Patentes, Sorteios, Parceiros e Notificações

Data: 13/09/2026

## 1. Objetivo

Fechar quatro jornadas prioritárias do Vita Clube:

1. Atualização automática de patente pelo tempo efetivamente ativo no plano.
2. Participação do membro e execução automática de sorteios por patente.
3. Consolidação das validações de parceiros exclusivamente para o perfil Financeiro.
4. Homologação e integração das notificações imediatas desses eventos.

Este plano considera o código, as migrations e as Edge Functions existentes. O PIX recorrente da Woovi será tratado separadamente no Linear.

## 2. Fora do escopo desta entrega

- PIX Automático e Mercado Pago.
- Indique um amigo.
- Cupons.
- Grade de horários.
- Histórico de economia de parceiros para o membro.
- Agendamento manual de campanhas de notificação.
- Exclusão de conta e relatórios financeiros gerais que não sejam de parceiros.

## 3. Regras de produto adotadas

### 3.1 Patente

A fonte de verdade será o tempo em que o membro teve acesso pago e ativo, não `profiles.member_since`.

Regra inicial proposta:

| Patente | Tempo ativo acumulado |
|---|---:|
| Bronze | de 0 a 5 meses |
| Prata | de 6 a 11 meses |
| Ouro | de 12 a 23 meses |
| Diamante | 24 meses ou mais |

- Consultas, indicações e tipo de plano deixam de bloquear a progressão.
- Cancelamento ou inadimplência encerram o intervalo ativo e pausam a contagem.
- Se ainda existir um período já pago, a contagem vai até o fim desse direito de acesso.
- Reativação abre um novo intervalo e continua a partir do tempo acumulado.
- Downgrade não acontece por cancelamento; a patente conquistada é preservada, mas para de avançar. Se a regra comercial desejar downgrade, isso deverá ser uma decisão separada.
- Os valores de 6, 12 e 24 meses devem permanecer configuráveis na tabela `badges`, sem regras duplicadas no Flutter.

### 3.2 Sorteios

- O membro participa voluntariamente pelo app, tocando em **Participar**.
- É permitida uma inscrição por membro em cada sorteio.
- A assinatura precisa estar ativa tanto na inscrição quanto na execução.
- Cada sorteio define `eligible_badges`; isso permite sorteio exclusivo ou cumulativo sem nova migration.
- Regra inicial recomendada: sorteio Bronze aceita Bronze ou superior; Prata aceita Prata ou superior; Ouro aceita Ouro ou Diamante; Diamante aceita somente Diamante.
- A patente utilizada para a elegibilidade é a patente vigente no momento da execução.
- O sorteio é executado automaticamente no servidor, de forma transacional e auditável.
- O aplicativo administrativo não escolhe o vencedor e não executa aleatoriedade local.

### 3.3 Parceiros

- O fluxo atual de validação continua sendo operado pelo parceiro.
- Não será criada nova tela de histórico para o membro nesta entrega.
- Dados consolidados de uso, desconto e economia ficam disponíveis apenas para `financeiro` e `admin`.

### 3.4 Notificações

- Não haverá tela ou regra de agendamento de campanhas.
- Serão mantidos o envio imediato administrativo e notificações disparadas por eventos do sistema.
- Eventos prioritários: patente atualizada, inscrição confirmada, sorteio realizado e membro vencedor.

## 4. Arquitetura e dependências

```text
Alteração da assinatura
        ↓
Intervalos de acesso ativo → cálculo da patente → evento de promoção
                                      ↓                 ↓
                              elegibilidade do sorteio  notificação
                                      ↓
                         inscrição e execução automática
                                      ↓
                              resultado + notificação

Validação do parceiro → dados consolidados → dashboard do Financeiro
```

Toda regra crítica deve ficar em funções SQL/RPC com `SECURITY DEFINER`, `search_path` fixo, validação de `auth.uid()` e políticas RLS restritivas. O Flutter apresenta o resultado e solicita ações, mas não decide patente, elegibilidade ou vencedor.

## 5. Fase 1 — Patente automática

### 5.1 Banco de dados

Criar uma migration para:

- Criar `membership_active_periods` com `user_id`, `subscription_id`, `started_at`, `ended_at`, `source` e timestamps.
- Garantir que um usuário tenha no máximo um intervalo aberto por assinatura.
- Criar trigger sobre mudanças relevantes de `subscriptions` para abrir ou fechar intervalos.
- Criar função `member_active_days(user_id)` para somar somente períodos ativos.
- Criar RPC idempotente `recalculate_member_badge(user_id)`.
- Atualizar `badge_progress` e a patente espelhada na assinatura na mesma transação.
- Criar `badge_upgrade_events` com restrição única por usuário e patente conquistada.
- Popular as quatro patentes em desenvolvimento e produção.
- Normalizar os valores persistidos para `bronze`, `prata`, `ouro` e `diamante`.

O backfill de usuários existentes deve usar os períodos de assinatura conhecidos. Quando não houver histórico suficiente, o registro precisa ser marcado como estimado para revisão do Financeiro, sem usar silenciosamente a data de cadastro.

### 5.2 Execução automática

- Recalcular ao ativar, renovar, suspender, cancelar ou reativar uma assinatura.
- Executar uma rotina diária para promoções que dependem apenas da passagem do tempo.
- Permitir que a Home invoque a mesma RPC idempotente ao abrir ou voltar ao primeiro plano, garantindo atualização imediata mesmo se a rotina diária atrasar.

### 5.3 Flutter

- Remover do app o cálculo de elegibilidade por consultas/indicações.
- Corrigir a conversão entre os nomes portugueses do banco e o enum visual em inglês.
- Fazer o BLoC carregar o progresso retornado pelo servidor.
- Atualizar a assinatura exibida na Home após a promoção.
- Exibir modal de conquista uma única vez por `badge_upgrade_event` ainda não visualizado.
- Atualizar a folha de detalhes usando requisitos vindos do banco.

### 5.4 Critérios de aceite

- Seis meses pagos promovem Bronze para Prata sem ação administrativa.
- Um período cancelado/inadimplente não aumenta `active_days`.
- Reativação continua a contagem sem perder o período anterior.
- Abrir ou retomar a Home mostra a patente correta.
- O modal de conquista não reaparece indefinidamente.
- Duas chamadas simultâneas de recálculo não criam eventos duplicados.
- Usuário autenticado não consegue alterar sua própria patente diretamente.

## 6. Fase 2 — Sorteios por patente

Depende da Fase 1 para usar uma patente confiável.

### 6.1 Banco e segurança

- Revisar `draws` e adicionar, se necessário, abertura, encerramento de inscrições e horário real de execução.
- Substituir o INSERT direto em `draw_participants` por `join_draw(draw_id)`.
- Na RPC, validar janela de inscrição, assinatura ativa, patente elegível e duplicidade.
- Criar `leave_draw(draw_id)` somente enquanto as inscrições estiverem abertas.
- Fortalecer `execute_draw(draw_id)` com lock transacional, seed gerada no servidor, lista ordenada, hash de participantes e registro de auditoria.
- Revalidar assinatura e patente dos participantes no instante da execução.
- Impedir UPDATE direto de vencedor, status e campos de auditoria pelo cliente.
- Criar rotina automática que encerra inscrições e executa sorteios vencidos.

### 6.2 Jornada do membro

- Criar módulo de sorteios do membro com lista de abertos, próximos e realizados.
- Mostrar prêmio, regras, patentes elegíveis, prazo e status da participação.
- Disponibilizar **Participar** e **Cancelar participação** durante a janela permitida.
- Exibir vencedor e auditoria resumida após a execução.
- Adicionar entrada na Home ou no menu principal.

### 6.3 Administração

- Manter criação, edição e cancelamento de sorteios.
- Trocar a execução aleatória local pela RPC do servidor.
- Mostrar quantidade de inscritos elegíveis e resultado.
- Tratar upload real da imagem do prêmio ou remover temporariamente o controle placeholder.

### 6.4 Critérios de aceite

- Bronze não entra em sorteio exclusivo Prata, Ouro ou Diamante.
- Membro não consegue se inscrever duas vezes.
- Membro cancelado/inadimplente antes da execução não concorre.
- O sorteio acontece uma única vez mesmo com execuções concorrentes.
- O vencedor pertence ao snapshot auditado de participantes elegíveis.
- Membro consegue acompanhar inscrição e resultado pelo app.

## 7. Fase 3 — Parceiros para o Financeiro

Pode ser desenvolvida em paralelo com a Fase 2.

### 7.1 Segurança da validação

- Unificar validação e confirmação, ou gerar uma sessão/nonce de uso único com expiração curta.
- Impedir que o cliente confirme uma utilização informando livremente outro `user_id`.
- Manter INSERT/UPDATE/DELETE de `partner_validations` exclusivos das RPCs/service role.

### 7.2 Consolidação financeira

Criar view ou RPC agregada, filtrável por período e parceiro, contendo:

- quantidade de validações;
- membros únicos;
- valor bruto informado;
- economia/desconto concedido;
- valor final estimado;
- ticket médio;
- divisão por serviço e patente;
- evolução diária ou mensal.

### 7.3 Flutter Financeiro

- Adicionar visão consolidada no dashboard Financeiro.
- Permitir filtro por período, parceiro e serviço.
- Abrir detalhe do parceiro com série histórica e últimas validações.
- Corrigir rótulos que tratam desconto/economia como receita.
- Permitir exportação CSV do período filtrado.
- Não expor esses relatórios ao membro ou ao perfil parceiro.

### 7.4 Critérios de aceite

- Financeiro e admin visualizam os dados consolidados.
- Membro e parceiro não acessam o relatório financeiro consolidado.
- Totais do relatório conciliam com `partner_validations` no mesmo período.
- Filtros utilizam o mesmo fuso horário adotado pelo negócio.
- Nenhuma confirmação pode ser reutilizada ou forjada para outro membro.

## 8. Fase 4 — Notificações imediatas

A base existente será consolidada, sem agendamento manual.

### 8.1 Backend

- Criar uma camada única/outbox para eventos de domínio que geram notificação.
- Gerar notificação de patente promovida dentro da transação de promoção.
- Gerar confirmação de inscrição após `join_draw`.
- Gerar resultado geral e notificação específica do vencedor após `execute_draw`.
- Registrar por campanha/evento: tokens encontrados, envios aceitos, falhas, tokens removidos e último erro.
- Mapear corretamente os tipos de evento às preferências do usuário.
- Garantir idempotência para que retries não dupliquem inbox ou push.

### 8.2 Flutter e homologação

- Abrir o destino correto ao tocar no push: Home/patente ou detalhe do sorteio.
- Atualizar o contador da inbox após eventos recebidos.
- Homologar Android em foreground, background e app encerrado.
- Homologar iOS em foreground, background e app encerrado.
- Validar refresh de token e limpeza de token inválido.

### 8.3 Critérios de aceite

- Promoção gera exatamente uma entrada na inbox e uma tentativa de push.
- Participação no sorteio aparece imediatamente na inbox.
- Vencedor recebe mensagem distinta do aviso geral de resultado.
- Preferência desativada impede o push correspondente, preservando notificações obrigatórias quando aplicável.
- A interface administrativa diferencia notificações criadas de pushes aceitos/falhos.

## 9. Ordem de entrega sugerida para o Linear

### Epic 1 — Patente automática

1. Migration de períodos ativos e backfill.
2. RPC transacional de cálculo/promoção.
3. Triggers e rotina diária.
4. Integração Home/BLoC e modal de conquista.
5. Testes de domínio, RPC, widget e ciclo cancelar/reativar.

### Epic 2 — Sorteios por patente

1. Regras finais de elegibilidade e migrations.
2. RPCs de inscrição, saída e execução.
3. Automação do encerramento/resultado.
4. Jornada do membro.
5. Ajustes administrativos e auditoria.
6. Testes de concorrência, segurança e ponta a ponta.

### Epic 3 — Financeiro de parceiros

1. Sessão segura de validação.
2. RPC/view de consolidação.
3. Dashboard, filtros e detalhe.
4. Exportação CSV.
5. Testes RLS e conciliação.

### Epic 4 — Notificações imediatas

1. Outbox e idempotência.
2. Eventos de patente e sorteio.
3. Métricas de envio e preferências.
4. Deep links.
5. Homologação Android/iOS em aparelho real.

## 10. Gates de liberação

Antes de cada publicação:

- migrations aplicadas e verificadas primeiro em desenvolvimento;
- dados de patentes semeados em produção;
- `flutter analyze lib test` sem erros;
- suíte unitária e de widgets integralmente verde;
- testes de RLS com membro, parceiro, financeiro e admin;
- teste de concorrência do sorteio;
- teste real de push em Android e iOS;
- textos da página de Benefícios alinhados às funcionalidades efetivamente liberadas;
- plano de rollback das migrations e feature flags para Home, sorteios e relatório de parceiros.

## 11. Decisões que devem ser confirmadas antes da implementação

1. Patente será realmente baseada somente no tempo ativo, substituindo consultas, indicações e plano anual?
2. Um membro mantém a patente já conquistada após cancelar, apenas deixando de progredir?
3. Sorteios são cumulativos por patente ou exclusivos para cada patente?
4. Cancelamento solicitado mantém elegibilidade até o fim do período já pago?
5. O valor final de uma utilização de parceiro é apenas informativo ou será usado em conciliação/pagamento ao parceiro?

