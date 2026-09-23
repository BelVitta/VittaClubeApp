# Checklist de testes e homologação — Vita Clube

Este documento organiza o que precisa ser testado antes de avançar para a próxima prioridade e antes de publicar o aplicativo.

## Regra geral

- [ ] Executar primeiro no Supabase DEV.
- [ ] Usar somente usuários, cartões e cobranças de teste.
- [ ] Não colocar Access Token, senha do banco ou segredo de Webhook no aplicativo.
- [ ] Registrar data, ambiente, usuário de teste, resultado e evidência (print ou consulta SQL).
- [ ] Não testar cobrança real em produção sem autorização explícita.

Ambiente DEV atual:

```text
Supabase project ref: nejjyjmfaipgkfyiyxkr
```

---

## Prioridade 1 — Pix Automático/Woovi

### 1.1 Criação da assinatura

- [ ] Usuário sem assinatura consegue iniciar o plano mensal.
- [ ] O plano exibido é mensal e custa R$ 34,90.
- [ ] O servidor resolve o preço; o aplicativo não consegue enviar outro valor.
- [ ] O e-mail, CPF e dados de cobrança usados são os do servidor.
- [ ] O token/segredo da Woovi não aparece no Flutter.
- [ ] A assinatura começa como `waiting_authorization` e `blocked`.
- [ ] Benefícios não são liberados antes da primeira cobrança aprovada.
- [ ] Duas solicitações simultâneas não criam duas assinaturas.

### 1.2 Aprovação da primeira cobrança

- [ ] Autorizar a cobrança no ambiente de teste da Woovi.
- [ ] Receber o Webhook aprovado.
- [ ] A assinatura muda para `active`.
- [ ] `payment_access_status` muda para `allowed`.
- [ ] `current_period_start` e `current_period_end` são preenchidos.
- [ ] QR Code, descontos e consultas passam a funcionar.
- [ ] O histórico registra exatamente um pagamento.

### 1.3 Recusa e inadimplência

- [ ] Recusa da primeira cobrança mantém a assinatura bloqueada.
- [ ] Uma falha de renovação preserva o acesso somente até o fim do período já pago.
- [ ] Depois de `current_period_end`, o acesso é bloqueado.
- [ ] QR Code, descontos, consultas e sorteios respeitam o bloqueio.
- [ ] Uma cobrança aprovada posteriormente reativa o acesso sem criar outro pagamento.

### 1.4 Webhooks Pix

- [ ] Webhook com assinatura inválida retorna HTTP 401.
- [ ] Webhook repetido não duplica pagamento nem período.
- [ ] Webhook de recusa recebido depois do aprovado não remove o acesso pago.
- [ ] Webhook de criação/autorização atrasado não desfaz uma assinatura já paga.
- [ ] Valor diferente de R$ 34,90 não libera benefício.
- [ ] Confirmar que o formato de assinatura RSA da Woovi está validado antes de produção.

Consulta SQL:

```sql
select id, user_id, payment_provider, status,
       payment_access_status, current_period_start,
       current_period_end, is_current
from public.subscriptions
where payment_provider = 'woovi'
order by updated_at desc;

select correlation_id, status, value_cents,
       attempt_count, paid_at
from public.subscription_charges
order by updated_at desc;
```

---

## Prioridade 2 — Segurança das funcionalidades críticas

### 2.1 Sorteios

- [ ] Usuário comum não consegue executar sorteio.
- [ ] Usuário anônimo não consegue executar sorteio.
- [ ] Admin consegue executar sorteio encerrado.
- [ ] Financeiro consegue executar sorteio encerrado.
- [ ] Um sorteio já realizado não pode ser executado novamente.
- [ ] Duas execuções simultâneas produzem apenas um vencedor.
- [ ] A semente é criada no PostgreSQL, nunca no Flutter.
- [ ] Participante com assinatura vencida não entra no sorteio.
- [ ] Participante bloqueado não entra no sorteio.
- [ ] O vencedor pertence à lista de participantes elegíveis.
- [ ] Alteração direta de `winner_id`, `winner_index` ou hashes é recusada.
- [ ] Existe registro de auditoria da execução.

Consulta SQL:

```sql
select id, status, winner_id, winner_index,
       participant_count, executed_at,
       draw_seed_hash, participant_list_hash
from public.draws
order by updated_at desc;
```

### 2.2 Validação de parceiro

- [ ] Parceiro ativo consegue ler uma carteirinha válida.
- [ ] Parceiro inativo é recusado.
- [ ] O resultado da leitura cria uma sessão temporária.
- [ ] A sessão expira após cinco minutos.
- [ ] A confirmação envia somente `validationId` e o valor original.
- [ ] O nome, titular, dependente, patente e desconto são resolvidos pelo servidor.
- [ ] Dependente de outro titular é recusado.
- [ ] Dependente inativo é recusado.
- [ ] Assinatura vencida ou bloqueada é recusada.
- [ ] Outra conta de parceiro não consegue usar a sessão.
- [ ] A mesma sessão não pode ser confirmada duas vezes.
- [ ] O percentual usado é o percentual vigente do acordo do parceiro.
- [ ] Usuário comum não consegue inserir validações diretamente na tabela.

Consulta SQL:

```sql
select id, partner_id, user_id, user_name,
       user_badge_level, discount_percentage,
       original_value, savings_amount,
       beneficiary_type, dependent_id, validated_at
from public.partner_validations
order by validated_at desc;
```

---

## Prioridade 3 — Conciliação e idempotência de cobranças

### 3.1 Fila de Webhooks Mercado Pago

- [ ] Webhook válido é registrado uma única vez.
- [ ] Evento duplicado retorna sucesso sem duplicar processamento.
- [ ] Dois workers não conseguem assumir o mesmo evento.
- [ ] Evento preso em `processing` é recuperado depois do vencimento do lease.
- [ ] Falha temporária volta para `failed` com próxima tentativa.
- [ ] Evento processado fica com `processed_at` preenchido.
- [ ] Evento ignorado fica identificado como `ignored`.

Consulta SQL:

```sql
select event_key, topic, resource_id,
       processing_status, attempt_count,
       processing_started_at, lease_until,
       received_at, processed_at, processing_error
from public.mercadopago_webhook_events
order by received_at desc;
```

### 3.2 Pagamentos Mercado Pago

- [ ] Primeira cobrança aprovada ativa a assinatura.
- [ ] Cobrança aprovada repetida cria uma única linha por `provider_payment_id`.
- [ ] Cobrança aprovada com moeda diferente de BRL não ativa.
- [ ] Cobrança aprovada com valor diferente do plano não ativa.
- [ ] Webhook antigo não reduz `current_period_end`.
- [ ] Cobrança aprovada posterior estende o período corretamente.
- [ ] Cobrança recusada preserva somente um período pago vigente.
- [ ] Período vencido bloqueia a assinatura.
- [ ] Webhook perdido é recuperado pela consulta remota paginada.
- [ ] Cancelamento externo é refletido localmente sem remover período já pago.

Consulta SQL:

```sql
select provider_payment_id, provider_authorized_payment_id,
       subscription_id, amount_cents, currency,
       status, paid_at, period_start, period_end
from public.mercadopago_authorized_payments
order by paid_at desc;
```

### 3.3 Criação duplicada

- [ ] Duplo toque no botão de contratar não cria duas recorrências.
- [ ] Timeout do provedor permite repetir usando o mesmo registro local.
- [ ] Uma assinatura `waiting_authorization` continua impedindo nova contratação.
- [ ] Registro local sem resposta do provedor é identificado para reconciliação.
- [ ] Assinatura rejeitada pode ser tentada novamente somente após ficar terminal.

---

## Prioridade 4 — Histórico financeiro e telas

- [ ] Pagamento aprovado aparece no histórico do membro.
- [ ] Pagamento aprovado aparece nas métricas do Financeiro.
- [ ] O total financeiro coincide com o ledger do provedor.
- [ ] Pagamento duplicado não duplica receita.
- [ ] Cancelamento mostra a data final de acesso.
- [ ] Tela de processamento não consulta o servidor mais vezes que o limite permitido.
- [ ] Erro de Webhook mostra estado de processamento, sem liberar benefício prematuramente.
- [ ] Recibo não mostra botões sem implementação.
- [ ] Exclusão de conta registra uma solicitação real ou não promete uma ação inexistente.
- [ ] Mensagens de inadimplência explicam como regularizar.

---

## Prioridade 5 — Preparação para Play Store

### Android

- [ ] Identificador definitivo do aplicativo foi escolhido.
- [ ] O mesmo identificador está no Firebase e no Play Console.
- [ ] `google-services.json` correto está em `android/app/`.
- [ ] Keystore de upload foi criado e guardado fora do Git.
- [ ] `android/key.properties` não está versionado.
- [ ] Release não usa assinatura de debug.
- [ ] `versionCode` foi incrementado.
- [ ] `targetSdk` atende ao requisito vigente do Google Play.
- [ ] Nenhum Access Token ou segredo está no AAB.

### Build

```bash
flutter analyze
flutter test
flutter build appbundle --release -t lib/main_prod.dart
```

- [ ] O build termina sem erro.
- [ ] O arquivo `.aab` foi gerado.
- [ ] O aplicativo abre apontando para o Supabase de produção somente no build PROD.
- [ ] O build DEV continua exibindo o ambiente de desenvolvimento.

### Play Console

- [ ] Aplicativo criado com o identificador definitivo.
- [ ] Play App Signing configurado.
- [ ] `.aab` enviado para teste interno.
- [ ] Usuários de teste adicionados.
- [ ] Login, Pix, carteirinha, QR, parceiro e cancelamento testados no aparelho.
- [ ] Política de privacidade publicada em HTTPS.
- [ ] Formulário de segurança dos dados preenchido.
- [ ] Só depois dos testes internos: iniciar publicação gradual.

---

## Evidência mínima para considerar uma prioridade concluída

Para cada prioridade, guardar:

- [ ] data e ambiente do teste;
- [ ] usuário/conta de teste utilizada;
- [ ] entrada usada;
- [ ] resultado esperado;
- [ ] resultado obtido;
- [ ] print ou log;
- [ ] consulta SQL relevante;
- [ ] falhas conhecidas e decisão sobre elas.

Uma prioridade só deve ser marcada como concluída quando os testes positivos, negativos, duplicados e fora de ordem tiverem sido executados.

