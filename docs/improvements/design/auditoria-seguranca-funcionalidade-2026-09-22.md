# Auditoria de segurança e funcionalidade — 22/09/2026

## Conclusão

O aplicativo ainda não está completamente funcional e não deve ser considerado pronto para cobrança em produção. Há falhas de autorização/integridade no código SQL, inconsistências no ciclo de cobrança e funcionalidades visíveis sem implementação completa.

Esta é uma revisão de código com testes locais, não um pentest nem uma certificação. Os achados descrevem o estado atual do workspace, incluindo alterações locais ainda não commitadas. Não foram alterados códigos de produção, credenciais, dados remotos ou configurações de serviços durante a auditoria. Este relatório é o único arquivo adicionado.

## Escopo e limites

- Inventário: 21 features, 550 arquivos Dart em `lib`, 76 arquivos de páginas, 68 arquivos de testes unitários/widget, 48 migrações e 17 diretórios de endpoints Edge Functions.
- Inspeção de rotas, telas, contratos, datasources, políticas de acesso, SQL/RLS e integrações de cobrança. Inventariar todas as features não significa testar manualmente todas as telas ou provar ausência de vulnerabilidades em cada linha.
- Excluídos artefatos gerados, dependências vendorizadas e cópias locais do projeto.
- Não houve teste de invasão contra ambientes remotos, transação real, homologação de cartão/Pix, teste de concorrência no PostgreSQL nem verificação dos grants efetivamente aplicados no Supabase.
- Deno, PostgreSQL/psql e Docker não estavam disponíveis nos caminhos verificados. Não foram executados os testes Deno/SQL nem um reset local do banco.
- Não foi feito novo build release nesta auditoria, análise completa de CVEs das dependências ou teste visual de acessibilidade em dispositivos.

## Verificação executada

| Verificação | Resultado |
| --- | --- |
| `dart analyze lib test integration_test` | 3 erros e 8 avisos informativos de estilo |
| `flutter test --no-pub` | 152 testes passaram; 2 falharam |
| Reexecução dos dois testes com falha | Mesmas falhas confirmadas |
| Busca limitada por segredos em arquivos rastreados | Não foi encontrado segredo literal nos padrões pesquisados; não equivale a auditoria de todo o histórico Git |

Os três erros estão em `integration_test/onboarding_flow_test.dart:19`: `expect` não está definido/importado. Os oito avisos de estilo estão em `admin_user_form_page.dart`, relacionados a chaves em condicionais.

Os testes com falha são `test/features/dependents/dependents_subscription_gate_test.dart` e `test/features/consultation/consultation_subscription_gate_test.dart`. Esperam o modal antigo de reativação, mas a navegação atual abre planos; o fixture também não inicializa `AppConfig`. Isso evidencia testes desatualizados/incompletos, não prova sozinho que a mesma exceção ocorre no aplicativo inicializado normalmente.

## Achados prioritários

Prioridade P1: corrigir antes de produção. P2: corrigir antes de considerar a funcionalidade concluída. As consequências de cobrança descritas abaixo são cenários derivados do código, não cobranças indevidas observadas em uma conta real.

### S01 — P1: execução de sorteio sem autorização explícita no SQL

Evidência: `supabase/schema.sql:893`, função `execute_draw`, termina com `SECURITY DEFINER` na linha 943, sem autenticação, checagem de perfil ou revogação específica encontrada no repositório. O chamador fornece também o seed que determina o vencedor.

Se essa definição estiver implantada com os privilégios padrão, usuários não autorizados poderão tentar executar um sorteio pronto e influenciar seu resultado. PostgreSQL concede `EXECUTE` a `PUBLIC` por padrão para funções; os privilégios reais do ambiente precisam ser conferidos. [Documentação PostgreSQL 17](https://www.postgresql.org/docs/17/ddl-priv.html).

Correção necessária: autorização interna, grants mínimos, `search_path` fixo, trava/transição atômica e geração auditável do sorteio no servidor. Confirmar em dev a negativa para anon e usuário comum.

### S02 — P1: acesso pode continuar depois do fim do período pago

Evidências: `lib/features/subscription/domain/services/subscription_access_policy.dart:16` e `supabase/migrations/20260826000100_loyalty_mvp_partner_validation.sql:84` permitem acesso para `active`/`payment_pending` sem verificar `current_period_end`. Já `supabase/functions/reconcile-mercadopago/index.ts:293` expira somente `payment_pending` e `cancelled`, não `active`.

Uma assinatura que permaneça ativa por perda de notificação de renovação pode manter acesso vencido. Além disso, `reconcile-mercadopago-subscription/index.ts:50` reativa a partir de uma cobrança aprovada antiga sem conferir se o período calculado ainda está vigente. O cliente concede o dia inteiro de cancelamento, enquanto o SQL compara o instante, criando outra divergência.

Correção necessária: política única de acesso por período pago válido, aplicada no servidor e no cliente; expiração também de ativos sem renovação e conciliação que não reative por pagamento antigo.

### S03 — P1: primeira cobrança Pix recusada pode liberar benefícios

Evidência: `supabase/functions/woovi-webhook/index.ts:231`, `markPaymentPending`, grava `payment_pending` e `warning_pending` sem exigir pagamento anterior. Com a política de S02, esse estado libera QR e benefícios mesmo sem primeiro período pago.

A assinatura do webhook existe; o problema é a transição de estado após um evento autêntico, não aceitação de qualquer chamada anônima.

Correção necessária: manter acesso bloqueado antes do primeiro pagamento; uma falha de renovação só preserva acesso até o término de um período previamente pago.

### S04 — P1: parceiro consegue confirmar utilização sem validar elegibilidade do beneficiário

Evidência: `supabase/migrations/20260826000100_loyalty_mvp_partner_validation.sql:395`. `confirm_partner_validation` verifica que o chamador é parceiro ativo, mas aceita titular, dependente, nome e nível informados pelo cliente sem revalidar assinatura, vínculo do dependente ou resultado prévio da leitura da carteirinha.

Um parceiro autenticado pode registrar utilização/economia indevida. A migração posterior revoga INSERT direto, mas o wrapper com rate limit mantém a mesma implementação interna vulnerável. Não se trata de acesso público anônimo.

Correção necessária: resolver beneficiário e nível no servidor, verificar elegibilidade e vínculo e ligar a confirmação a uma validação válida, de uso controlado.

### B01 — P1: atualização de assinatura pendente pode permitir outra recorrência

Evidências: `supabase/functions/reconcile-mercadopago-subscription/index.ts:93` atribui `is_current: access !== "blocked"`; uma assinatura aguardando a primeira cobrança tem acesso bloqueado. `create-mercadopago-subscription/index.ts:47` procura duplicidade somente entre registros `is_current = true`. A tela `subscription_processing_page.dart:32` consulta imediatamente e a cada cinco segundos.

Assim, apenas entrar na tela de confirmação pode retirar a pendência do índice lógico de assinatura atual. Uma segunda tentativa pode criar outra recorrência enquanto a primeira continua no provedor.

Correção necessária: separar titularidade da recorrência de permissão de acesso; manter bloqueio de criação enquanto houver operação/recorrência não encerrada, com idempotência e exclusão mútua no banco.

### B02 — P1: cobrança aprovada antiga pode sobrescrever o período mais recente

Evidência: `supabase/functions/reconcile-mercadopago/index.ts:151` ignora eventos antigos apenas quando não aprovados. Uma cobrança aprovada sempre sobrescreve o período nas linhas 196–206, mesmo quando há pagamento posterior.

O upsert evita duplicar a mesma linha de pagamento, mas não torna a atualização da assinatura monotônica. Webhooks fora de ordem podem reduzir o período adquirido ou retroceder a próxima cobrança.

Correção necessária: processamento transacional e comparação com período/fatura já aplicados. Testar ordem invertida, duplicata e concorrência.

### B03 — P1: conciliação não recupera automaticamente todos os estados perdidos

Evidência: `supabase/functions/reconcile-mercadopago/index.ts:24` seleciona apenas eventos `received`/`failed`, muda para `processing` sem lease/trava e não recupera eventos abandonados nesse estado. O job processa eventos existentes, reajustes e vencimentos, mas não faz uma varredura periódica de assinaturas remotas para recuperar webhooks nunca recebidos. Eventos de plano são ignorados na linha 77.

Diversas gravações não verificam o erro retornado pelo Supabase, inclusive a atualização da assinatura na linha 196. A função de cancelamento também pode devolver sucesso apesar de erro na persistência local. O provedor e o banco podem divergir silenciosamente.

Correção necessária: claim atômico, recuperação de processamento interrompido, verificação de todos os erros, reconciliação remota paginada, observabilidade e alertas. Consulta manual não substitui recuperação automática.

### B04 — P1: cobrança Mercado Pago não alimenta histórico e receita financeira

Evidências: a conciliação grava `mercadopago_authorized_payments`; `lib/features/payments/data/datasources/payments_supabase_datasource.dart:16` e `lib/features/financeiro/data/datasources/financeiro_metrics_supabase_datasource.dart:21` leem `payments`. Não foi encontrada ponte de escrita/trigger entre os dois conjuntos.

Uma mensalidade confirmada pode não aparecer no histórico/recibo e não compor a receita do financeiro.

Correção necessária: ledger/consulta unificada, com unicidade por pagamento externo, preenchimento de dados históricos e conferência entre provedor, histórico e totais.

### B05 — P1: reajuste pode informar conclusão antes de terminar

Evidência: `supabase/functions/update-mercadopago-plan-price/index.ts:43` devolve `completed` quando o preço já coincide, antes de verificar job aberto. O preço local é alterado na linha 72 antes de concluir todos os assinantes. Repetir a solicitação nesse intervalo pode declarar conclusão prematuramente.

A criação de itens e outras atualizações não verificam todos os erros. A seleção de assinaturas não pagina, ficando dependente do limite de linhas configurado na API. O worker troca o valor esperado da assinatura, o que também exige tratamento de faturas antigas/em trânsito. A UI descarta `jobId/status` (`admin_supabase_datasource.dart:336`) e não oferece acompanhamento/repetição de falhas.

Correção necessária: estado durável do job como fonte da resposta, itens completos/paginados, vigência de preço por cobrança e painel de progresso/falhas. Revisar também a autorização: `hasBillingAdminRole` aceita admin, enquanto as políticas comerciais SQL reservam operações ao financeiro.

### F01 — P1: atualização de CPF/telefone é bloqueada pelo próprio trigger

Evidências: `supabase/migrations/20260710000400_user_sensitive_profile_rpc.sql:29` permite ao usuário chamar `update_user_sensitive_profile`. A migração posterior `20260711000600_rls_security_hardening.sql:108` instala trigger que rejeita mudanças em CPF/telefone para usuários comuns, inclusive mudanças feitas pela RPC.

`SECURITY DEFINER` não transforma o JWT do usuário em `service_role`; a autorização desse trigger continua falhando para atualização própria. Isso compromete correção de dados pessoais e conclusão de perfil quando necessária.

Correção necessária: desenhar um caminho privilegiado estreito que permita apenas a RPC autorizada, sem reabrir UPDATE direto. Testar usuário próprio, outro usuário, admin e financeiro no banco.

### S05 — P2: limite de tentativas pode ser contornado pelo próprio usuário

Evidência: `supabase/migrations/20260827000400_rate_limit_rpcs.sql:31`. A função exposta a `authenticated` aceita limite e janela definidos pelo chamador e apaga buckets anteriores à janela calculada.

Chamadas com a mesma ação e janela mais curta podem apagar o bucket da janela usada pelo endpoint. O limite deixa de ser uma defesa confiável contra abuso. Não foi executado ataque no serviço remoto.

Correção necessária: ação, janela e limite definidos pelo servidor; restringir acesso à implementação genérica e desacoplar limpeza de buckets de parâmetros do cliente.

### S06 — P2: dados pessoais persistidos sem proteção adicional no cache

Evidências: `lib/features/auth/data/services/auth_session_manager.dart:42` salva o JSON do usuário em SharedPreferences; `lib/features/auth/data/models/user_model.dart:28` inclui CPF e telefone, além de nome e e-mail.

São dados de perfil em armazenamento local sem a proteção do armazenamento seguro usado para a sessão. O risco depende de acesso ao dispositivo, extração/backup e configuração do sistema; não é uma exposição remota pública demonstrada.

Correção necessária: minimizar os dados em cache e mover campos sensíveis indispensáveis para armazenamento seguro, com limpeza consistente no logout.

## Funcionalidades e telas incompletas

### F02 — P2: confirmação de pagamento excede seu próprio rate limit

`subscription_processing_page.dart:33` consulta a cada cinco segundos, cerca de 12 vezes/minuto, além da consulta inicial e do botão manual. O endpoint permite 10/minuto (`reconcile-mercadopago-subscription/index.ts:26`). A espera normal pode produzir erros 429.

Faltam backoff, término adequado para cancelado/expirado, mensagem específica por provedor e uma ação real para corrigir o cartão recusado. O texto pede revisão do meio de pagamento, mas a tela oferece apenas nova consulta. Configuração ausente do SDK pode ocultar cartão sem explicar a indisponibilidade.

### F03 — P2: recibo tem ações sem implementação

`lib/features/payments/presentation/widgets/payment_receipt_sheet.dart:99`: Compartilhar e Baixar PDF têm callbacks vazios/TODO. O componente é acessível por `payments_page.dart:320`.

### F04 — P2: botão Excluir não exclui nem registra solicitação

`lib/features/profile/presentation/pages/privacy_data_page.dart:159`: a confirmação abre a política de privacidade. O texto orienta envio manual de e-mail, mas não registra pedido, não abre composição de e-mail e não fornece protocolo/estado. Ajustar rótulo e fluxo ou implementar a solicitação completa, incluindo tratamento da recorrência. Este achado não é um parecer jurídico.

### F05 — P2: indicações entre membros não fecham o ciclo

`lib/features/referral/data/datasources/referral_supabase_datasource.dart:57` busca código de outro usuário e faz UPDATE direto; as políticas em `supabase/schema.sql:844` permitem ao usuário leitura das próprias indicações e não fornecem a atualização comum esperada. `claimReward`, linha 87, também depende de UPDATE direto. Não foi encontrada ligação do caso de uso de validação ao fluxo de cadastro atual.

Não confundir com indicação por recepcionista, que é uma feature separada. Criar fluxo servidor autorizado e testar convite → cadastro → condição de recompensa → resgate, sem conceder escrita ampla ao cliente.

### F06 — P2: sorteios, benefícios e textos comerciais não estão alinhados

O SQL tem `register_for_draw`, mas não foi encontrada chamada dessa RPC no aplicativo nem jornada completa do membro para se inscrever. A administração sorteia no cliente (`admin_supabase_datasource.dart:940`), com hash que não determina o vencedor e sem transição condicional/atômica.

`benefits_page.dart:70` anuncia até 50% em consultas, e a página também anuncia sorteios mensais e aceleração por indicação. O catálogo atual de níveis usa descontos de 10/10/15/20%, progressão por meses pagos e limites específicos de sorteios. Os benefícios de parceiros podem variar, mas essa diferença precisa estar explícita; a tela não deve apresentar condições genéricas como garantias do plano.

Cupons e sorteios têm administração, mas não foi localizada uma jornada completa de resgate/participação para o membro. Isso não equivale a funcionalidades concluídas.

### F07 — P2: consultas dependem de operação manual; alguns toques não têm destino

O fluxo de solicitação usa WhatsApp; não equivale a reserva de horário confirmada com agenda e prevenção de conflito. A UI deve distinguir solicitação de confirmação. Em `home_page.dart:481`, o toque no item de consulta não abre detalhes.

### R01 — P1 para publicação: configuração release ainda é de desenvolvimento

`android/app/build.gradle.kts` mantém `applicationId = "com.example.vita_clube"` e `signingConfig` de debug no release. Definir identidade final e assinatura de upload/release, conferir configuração Firebase e executar o bundle release com configuração do ambiente correto. Não houve nova compilação release nesta revisão.

## Cobertura por feature

“Implementação presente” significa código/conexões encontrados, não aprovação ponta a ponta.

| Feature | Situação na revisão |
| --- | --- |
| auth | Autenticação e recuperação reais presentes; cache de PII precisa revisão. Tela antiga de código simulado encontrada sem rota de entrada identificada: código legado, não bypass de login comprovado. |
| splash | Inicialização/roteamento presentes; validar sessão expirada e erro de rede no dispositivo. |
| onboarding | Telas presentes; suite de integração não compila atualmente. |
| home | Composição presente; consulta com toque sem destino e dados dependentes das integrações auditadas. |
| card | Carteirinha/QR presentes; não aprovados enquanto política de acesso S02/S03 permitir elegibilidade indevida. |
| subscription | Bloqueadores de período, pendência, duplicidade e conciliação. |
| plans | Seleção/contratação presentes; configuração de cartão, estados finais e reajustes incompletos. |
| payments | Histórico desconectado das novas cobranças e recibo com botões vazios; cancelamento exige consistência remota/local. |
| profile | Edição de dados sensíveis conflita com trigger; exclusão incompleta. |
| dependents | Cadastro/validação presentes; herda falhas de elegibilidade e possui teste de reativação falhando. |
| consultation | Solicitação/QR presentes; operação híbrida com WhatsApp, teste de reativação falhando. |
| professionals | Catálogo presente; agenda confirmada ponta a ponta não demonstrada. |
| benefits | Textos/promessas precisam refletir catálogo, condições e funcionalidades realmente disponíveis. |
| badge_progress | Catálogo/progressão por ciclos pagos presentes; depende de conciliação correta e de textos alinhados. |
| referral | Validação/resgate incompatíveis com políticas atuais; ligação com cadastro não encontrada. |
| receptionist_referrals | Implementação separada presente; conversão/comissão e permissões precisam teste real por perfil. |
| parceiro | Leitura/validação presentes; confirmação não revalida beneficiário/vínculo. |
| admin | CRUDs presentes; sorteio, permissões comerciais e acompanhamento de reajustes precisam correção. |
| financeiro | Métricas consultam ledger diferente das novas cobranças; não homologado para fechamento. |
| notifications | Preferências/push/campanhas presentes; entrega real, logout/troca de usuário e repetição de campanha não homologados nesta revisão. |
| error | Componentes presentes; mensagens técnicas propagadas por alguns datasources e recuperação de falhas precisam revisão contextual. |

## O que já é uma boa base

- Separação em camadas e interfaces para provedores.
- Tokenização nativa de cartão implementada; Access Token destinado ao backend, não ao Flutter.
- Validação de assinatura de webhook e consulta canônica no Mercado Pago presentes, embora o processamento de estado ainda tenha as falhas descritas.
- RLS, grants restritos e RPCs autorizadas já existem em várias áreas; o problema não é ausência generalizada de segurança.
- Há testes unitários/widget úteis e a maioria passou. Eles não substituem testes reais de RLS, recorrência e bridge nativa.

## Ordem recomendada antes de lançar

1. Fechar autorização dos sorteios e confirmação do parceiro; unificar elegibilidade por período pago e corrigir primeiro pagamento Pix.
2. Corrigir exclusão mútua/idempotência da criação, ordem das faturas, persistência de cancelamento, recuperação do worker e reconciliação remota.
3. Unificar histórico financeiro e tornar reajustes observáveis, repetíveis e consistentes por vigência.
4. Corrigir RPC de dados pessoais, indicações, recibos, exclusão de conta e estados/mensagens de pagamento.
5. Corrigir testes atuais e adicionar regressões específicas para cada falha; executar SQL/RLS com anon, usuário A/B, parceiro, admin e financeiro.
6. Homologar no sandbox: aprovação, recusa inicial, renovação, webhooks fora de ordem/duplicados/perdidos, perda de conexão, cancelamento com período pago, reajuste parcial e concorrência de criação. Conferir cada resultado no provedor, banco, QR, histórico e financeiro.
7. Validar Android/iOS em dispositivo, ciclo de vida da tokenização, sessão/logout, notificações e acessibilidade; então gerar e testar release assinado.

Nenhum achado foi explorado em produção e nenhuma correção foi aplicada nesta auditoria.
