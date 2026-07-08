# VittaClube — Análise Completa para Testes Manuais e Produção

---

## 1. AUTH — Autenticação

### Testes Manuais

**Registro (Email/Senha)**
- Registrar com e-mail válido, senha forte → deve criar conta e enviar e-mail de verificação
- Registrar com e-mail já cadastrado → deve bloquear e exibir mensagem de erro
- Registrar com CPF inválido (tamanho errado, caracteres não numéricos) → validação no client
- Registrar com e-mail sem "@" ou domínio → validação no client
- Registrar com senha fraca (ex: "123") → deve rejeitar (qual critério mínimo está definido?)
- Tentar login sem verificar e-mail → qual comportamento? Block ou permissão?
- Registrar e fechar o app antes de verificar → ao abrir novamente, o estado é correto?

**Login (Email/Senha)**
- Login com credenciais corretas → home
- Login com senha errada → mensagem de erro sem revelar se o e-mail existe
- Login com e-mail inexistente → idem acima (não revelar qual campo está errado)
- Login sem conexão → mensagem de "sem internet", não crash
- Logout → sessão encerrada, não consegue navegar para páginas autenticadas
- Token expirado (matar app, esperar sessão vencer) → refresh automático ou redirect para login?

**Google Sign-In**
- Sign-in na primeira vez → cria perfil no Supabase com role "user"
- Sign-in com conta já existente → faz login normalmente
- Cancelar o fluxo do Google → volta para a tela de login sem erro
- Sign-in offline → mensagem de erro adequada

**Forgot Password**
- E-mail válido cadastrado → recebe link
- E-mail válido não cadastrado → exibir mensagem genérica (não confirmar se existe ou não — segurança)
- Clicar no link expirado → comportamento?
- Clicar no link já usado → comportamento?

**Perguntas de Regra de Negócio:**
> 1. Usuário com e-mail não verificado pode acessar o app?
> 2. Existe bloqueio de conta após N tentativas de login erradas?
> 3. O link de reset de senha tem qual tempo de expiração?

---

## 2. CARD — Cartão Digital e QR Code

### Testes Manuais

- Abrir cartão com assinatura ativa → exibe código de membro e QR code corretamente
- Abrir cartão com assinatura expirada → exibe cartão? Com aviso? Ou bloqueia?
- Abrir QR code sheet (modal) → QR gerado corretamente a partir do member code
- Tirar screenshot do QR → app tenta bloquear? (hoje provavelmente não)
- QR exibido sem conexão → funciona (gerado localmente)? ✓

### ⚠️ Problemas de Segurança Críticos

**QR Code Estático — Risco Alto para Produção**

O QR code atual é gerado a partir do código de membro (string fixa). Isso significa:
- Um screenshot do QR pode ser usado indefinidamente por qualquer pessoa
- Um parceiro mal-intencionado pode usar o mesmo QR de um membro em dezenas de estabelecimentos
- Não há como revogar um QR sem revogar o código de membro inteiro

**Recomendação antes de ir para produção:**
Gerar QR codes dinâmicos com validade de 5–15 minutos usando JWT ou token assinado (ex: `{userId, expiry, signature}`). O parceiro valida a assinatura + expiração via Supabase Edge Function.

---

## 3. SUBSCRIPTION E PLANS — Assinatura e Planos

### Testes Manuais

- Visualizar lista de planos → preços, benefícios e tipos (mensal/semestral/anual) corretos
- Sem assinatura ativa → telas de funcionalidades premium mostram paywall ou bloqueio?
- Com assinatura Bronze ativa → benefícios Bronze acessíveis, Gold bloqueado
- Assinatura vencida dentro do grace period → acesso mantido? Aviso exibido?
- Assinatura vencida fora do grace period → redirecionado para renovação
- Assinatura cancelada → status "cancelado" reflete na home e no cartão
- Assinatura inadimplente → qual experiência? Igual ao cancelado?

**Perguntas de Regra de Negócio:**
> 1. Qual é a duração do grace period após vencimento?
> 2. Usuário inadimplente vê aviso em qual tela?
> 3. Se o plano semestral/anual cancela no meio, há reembolso proporcional?
> 4. Pode ter mais de um plano ativo ao mesmo tempo? (o schema tem unique constraint, mas vale confirmar na UI)

---

## 4. CONSULTATION — Consultas

### Testes Manuais

- Agendar consulta com profissional disponível → status "agendada"
- Agendar quando já atingiu o limite mensal do badge level → deve bloquear com mensagem clara
- Cancelar consulta → status muda para "cancelada"; limite mensal é devolvido?
- Remarcar consulta → status "remarcada"; data original mantida no histórico?
- Visualizar profissional sem disponibilidade → não deve aparecer ou mostra indisponível?
- WhatsApp launcher → abre WhatsApp com número correto do profissional?

**Perguntas de Regra de Negócio:**
> 1. Cancelar uma consulta agendada devolve a cota mensal do usuário?
> 2. Consulta "realizada" é marcada manualmente pelo admin ou automaticamente?
> 3. Existe confirmação de presença pelo usuário ou profissional?
> 4. O limite `max_consultations_per_month` é por mês calendário ou janela de 30 dias?

---

## 5. BADGE PROGRESS — Progressão de Badges

### Testes Manuais

- Bronze com 0 consultas e 0 indicações → tela de progresso exibe barras zeradas
- Realizar N consultas (threshold de upgrade) → badge avança automaticamente?
- Realizar N indicações válidas → contagem incrementa
- Ter plano anual ativo → `has_annual_plan = true` reflete no progresso
- Visualizar progresso após cancelamento de plano → badge regride ou mantém?
- Upgrade de badge → notificação ou feedback visual ao usuário?

**Perguntas de Regra de Negócio:**
> 1. O badge regride se o usuário cancelar ou ficar inadimplente?
> 2. Uma consulta "cancelada" conta para o progresso de badge?
> 3. Qual é o critério exato de cada nível (número de consultas/indicações por level)?

---

## 6. REFERRAL — Indicações

### Testes Manuais

- Gerar link de indicação → link único criado com código único
- Mesmo usuário tentar se auto-indicar → deve bloquear (regra no backend?)
- Indicado se cadastrar com link → status vai para "pending"
- Indicado ativar plano → status vai para "active"
- Indicado completar 1 consulta E ter 60+ dias ativos → status "active", recompensa liberada
- Solicitar recompensa (claim) → status vai para "rewarded", não pode ser solicitado de novo
- Indicação que expirou → status "expired", recompensa não pode ser solicitada

### ⚠️ Riscos de Segurança

- **Auto-indicação**: há prevenção no RLS/backend além do client?
- **Múltiplas contas com mesmo CPF**: usuário cria conta fake para se auto-indicar
- **Manipulação da data de 60 dias**: a contagem é feita no backend/DB? Não pode ser alterada pelo client

**Perguntas de Regra de Negócio:**
> 1. O que o usuário ganha ao reivindicar a recompensa? (crédito, desconto, mês grátis?)
> 2. Existe limite de indicações por usuário?
> 3. A verificação dos 60 dias é feita no frontend ou em uma Edge Function?

---

## 7. PARCEIRO — Parceiros e QR Validation

### Testes Manuais (Fluxo do Parceiro)

- Parceiro faz login → acessa painel de parceiro, não acessa admin de outros módulos
- Parceiro acessa QR scanner → câmera abre corretamente
- Scanear QR de membro ativo com plano elegível → exibe nome, badge level, serviços disponíveis
- Scanear QR de membro com assinatura expirada → deve rejeitar ou exibir aviso claro
- Scanear QR de membro inadimplente → comportamento esperado?
- Selecionar serviço e validar desconto → entrada criada em `partner_validations`
- Validar o mesmo membro duas vezes no mesmo dia → deve bloquear? (hoje não há essa regra aparente)
- Parceiro tenta acessar dados de outros parceiros → RLS deve bloquear
- `RegenerateCode` → código antigo deixa de funcionar imediatamente?

### Testes (Fluxo do Membro)

- Visualizar lista de parceiros → apenas parceiros `is_active = true`
- Filtrar por categoria (lab, clínica, farmácia, etc.)
- Ver serviços de um parceiro → preços original e com desconto corretos
- Sem assinatura ativa → consegue ver parceiros mas não pode validar desconto?

### ⚠️ Riscos de Segurança e Cenários Não Cobertos

- **Sem expiração no QR**: membro pode tirar screenshot e usar em outro local (ver seção 2)
- **Sem cooldown por membro/parceiro**: não há regra impedindo o mesmo parceiro de validar o mesmo membro N vezes por dia — alguém poderia usar isso para inflar relatórios
- **Desconto calculado onde?**: `discounted_price` é pré-configurado no cadastro do serviço, não calculado dinamicamente pelo badge level. Se isso é intencional, ok — mas vale confirmar
- **Partner code estático**: o `code` do parceiro é único mas não muda automaticamente; se vazar, qualquer pessoa pode tentar usá-lo

**Perguntas de Regra de Negócio:**
> 1. Há limite de validações por membro por dia/semana no mesmo parceiro?
> 2. O desconto varia por badge level dinamicamente ou é fixo por serviço?
> 3. Parceiro pode ter múltiplos usuários com role "parceiro" para o mesmo estabelecimento?
> 4. O que acontece se o parceiro escanear um QR fora do horário de funcionamento?

---

## 8. DRAWS — Sorteios

### Testes Manuais

- Visualizar sorteios com status "inscricoes_abertas" → listado para o usuário
- Inscrição com plano elegível → entrada em `draw_participants` criada, sem duplicata
- Inscrição com plano NÃO elegível → bloqueado com mensagem clara
- Inscrição com assinatura expirada → bloqueado
- Cancelar inscrição → possível? Não há usecase para isso aparentemente
- Admin executa sorteio → winner selecionado, hashes gerados, status → "realizado"
- Visualizar vencedor após sorteio → exibido para todos?
- Admin tenta executar sorteio não encerrado → deve bloquear
- Sorteio cancelado → usuários inscritos são notificados?

### ⚠️ Análise do Design de Sorteios para Produção

**O que está bem:**
- `draw_seed_hash` e `participant_list_hash` (SHA-256) garantem auditabilidade pós-sorteio
- `UNIQUE(draw_id, user_id)` impede inscrição dupla no DB
- Filtragem por `eligible_plan_levels` garante elegibilidade

**O que precisa atenção antes de produção:**
- **Quem executa o sorteio?** Hoje é um admin via UI. Risco: admin executa múltiplas vezes até sair o vencedor desejado — o hash do seed deve ser **comprometido publicamente antes** da execução
- **O algoritmo de seleção do vencedor** (`winnerIndex`) não está visível no código, só o índice final. O algoritmo deve ser determinístico e auditável externamente
- **Regulamentação no Brasil**: sorteios com prêmios podem exigir autorização da SEAE/MF dependendo do valor e da forma de participação. Verificar se o critério de participação (assinatura paga) configura como "modalidade lotérica"
- **`participant_list_hash` gerado na hora da execução**: se a lista for modificada entre o fechamento das inscrições e a execução, o hash não protege retroativamente

**Perguntas de Regra de Negócio:**
> 1. O sorteio pode ser auditado publicamente? O seed é publicado antes da execução?
> 2. Existe notificação automática ao vencedor?
> 3. Há restrição de quantos sorteios o mesmo usuário pode ganhar por período?
> 4. O cancelamento do plano antes do sorteio retira o usuário da lista?

---

## 9. PAYMENTS — Pagamentos (Mock → Produção)

### Testes Manuais (com Mock)

- Visualizar histórico de pagamentos → itens listados com status correto
- Pagamento aprovado → assinatura ativa
- Pagamento pendente (PIX/boleto) → assinatura ativa só após confirmação?
- Pagamento cancelado → o que acontece com a assinatura?
- Cancelar plano → fluxo de motivo de cancelamento → status atualizado
- Ver recibo de pagamento → dados corretos exibidos

### ⚠️ Checklist Crítico Antes de Integrar Gateway Real

- [ ] Nunca armazenar dados de cartão no DB — usar tokenização do gateway (Stripe/Pagar.me)
- [ ] Webhook do gateway para confirmar pagamentos (não confiar só no retorno síncrono)
- [ ] Idempotência: reenvio do webhook não deve criar pagamento duplicado
- [ ] PIX: expiração do QR code (ex: 30 min) — o que acontece com a assinatura?
- [ ] Boleto: vencimento de 1–3 dias úteis — assinatura fica em "pending" até confirmação
- [ ] Cobrança recorrente: quem dispara a renovação mensal/semestral/anual?
- [ ] Retry de cobrança falha: quantas tentativas? Com qual intervalo?
- [ ] Estorno: fluxo de `status = estornado` impacta assinatura imediatamente?

**Perguntas de Regra de Negócio:**
> 1. Qual gateway será usado (Stripe, Pagar.me, Mercado Pago, Iugu)?
> 2. A renovação é automática (cobrança recorrente) ou o usuário renova manualmente?
> 3. Existe período de carência após falha de cobrança antes de suspender o plano?

---

## 10. ADMIN — Painel Administrativo

### Testes Manuais

- Login com role "user" → não deve acessar nenhuma rota /admin
- Login com role "financeiro" → acessa módulo financeiro, mas não user_admin ou plan_admin?
- Login com role "admin" → acessa tudo
- Login com role "parceiro" → acessa apenas painel de parceiro
- Escalação de privilégio: usuário tenta alterar próprio role via API → RLS deve bloquear
- CRUD de especialidades → criar, editar, desativar (não deletar — há consultas vinculadas?)
- CRUD de profissionais → vincular especialidade, adicionar horários disponíveis
- Desativar plano com assinantes ativos → o que acontece com os assinantes?

**Perguntas de Regra de Negócio:**
> 1. Existe log de ações administrativas (audit log)?
> 2. Role "financeiro" tem acesso a quais módulos exatamente?
> 3. Deletar um profissional com consultas agendadas — qual o comportamento?

---

## 11. NOTIFICATIONS — Notificações

### Testes Manuais

- Receber notificação push com app em foreground → exibida como in-app
- Receber notificação push com app em background → exibida na bandeja do SO
- Tap na notificação → navega para a tela correta?
- Marcar como lida → `read_at` atualizado
- Visualizar histórico de notificações → ordenado por data

---

## 12. SEGURANÇA GERAL — Checklist para Produção

### Supabase / Backend

- [ ] **RLS habilitado em todas as tabelas** — verificar se alguma tabela ficou sem policy (risco de full table scan público)
- [ ] **`is_admin()` e `is_parceiro()`**: funções SQL verificam o role do usuário autenticado — confirmar que não podem ser bypassadas
- [ ] **CPF e telefone criptografados** com pgcrypto — ✓ já implementado
- [ ] **Rate limiting no Supabase**: Supabase tem rate limit nativo por IP para auth endpoints (login, signup). Para Edge Functions e queries, considerar rate limiting via `pg_rate_limit` ou middleware
- [ ] **Row-level security para `partner_validations`**: parceiro só cria, não altera — validar se UPDATE está bloqueado

### Rate Limiting — O que Implementar

| Endpoint / Ação | Risco sem Rate Limit | Solução |
|---|---|---|
| Login (email+senha) | Brute force de senha | Supabase já limita (configurável) |
| Register | Spam de contas fake | Rate limit por IP via Supabase Auth |
| Forgot password | Spam de e-mails | Rate limit nativo Supabase Auth |
| QR code scan (parceiro) | Enumerar códigos de membros | Supabase Edge Function com limite/min |
| Claim referral reward | Tentativas repetidas | Idempotência + unique constraint no DB |
| Draw inscription | Inscrição em massa | UNIQUE constraint já previne duplicatas |

### Flutter / Client

- [ ] **Não armazenar tokens sensíveis em SharedPreferences** — usar `flutter_secure_storage`
- [ ] **Chaves de API** (Supabase URL + anon key) não devem estar hardcoded no código de produção — usar variáveis de ambiente compiladas
- [ ] **Certificate pinning**: para produção com dados sensíveis, considerar validar o certificado do servidor
- [ ] **Obfuscation**: `flutter build apk --obfuscate --split-debug-info=...` para dificultar engenharia reversa
- [ ] **Deep links para reset de senha**: validar que o app não aceita deep links de domínios não autorizados

---

## 13. TIPOS DE TESTES — Estratégia Geral

### Testes Unitários (já existem para Auth)
- Expandir para todos os UseCases: cada use case deve ter testes com cenário de sucesso e falha
- Entities com lógica de negócio (ex: `ReferralEntity.isEligibleForReward()`)
- Validators (CPF, email, telefone)

### Testes de Widget
- Formulários: validação visual de campos
- Páginas com estados BLoC: loading, success, error
- Cartão digital: exibe dados corretos por status de assinatura

### Testes de Integração (e2e)
- Fluxo completo de registro → onboarding → escolha de plano → pagamento → cartão ativo
- Fluxo parceiro: login → scan QR → validação de desconto → entrada registrada
- Fluxo referral: indicar → indicado se cadastra → completa consulta → claim recompensa

### Testes Manuais Prioritários (antes de pagamentos)
1. Auth completo (todos os fluxos acima)
2. Cartão digital + QR gerado corretamente
3. Parceiro consegue scanear e validar
4. Badge progress atualiza após consulta
5. Referral cria link único e rastreia corretamente
6. Admin não acessível por usuário comum

---

## 14. O QUE PODE NÃO FAZER SENTIDO / PONTOS DE ATENÇÃO

| Item | Observação |
|---|---|
| **Firebase só para Google Sign-In** | Adiciona dependência, custo e complexidade desnecessários. O Supabase suporta OAuth com Google diretamente sem Firebase. Vale migrar antes da produção. |
| **QR code estático** | Para um app de saúde com descontos reais, QR estático é risco. Migrar para QR dinâmico com expiração antes do lançamento. |
| **`discounted_price` fixo por serviço** | Se o desconto deve variar por badge level (Bronze 10%, Ouro 25%), isso não está implementado dinamicamente — o parceiro cadastra um preço fixo. Confirmar se a regra é essa mesmo. |
| **Sorteio sem seed público** | Se o objetivo é transparência, o seed hash deve ser publicado ANTES do fechamento das inscrições — senão não garante fairness. |
| **Cancelamento de inscrição em sorteio** | Não há UseCase para isso. É intencional (inscreveu, não pode sair)?  |
| **Profissional sem agenda real** | O campo `available_days[]` é uma lista de dias da semana, não uma agenda de horários real. Isso limita muito o agendamento. |
| **Coupon sem vínculo obrigatório com pagamento** | `coupon_usages` tem `payment_id` nullable — coupon pode ser "usado" sem gerar pagamento? |
| **Roles sem separação fina no admin** | "financeiro" e "admin" não têm fronteiras claras no código além de funções SQL. Testar se um `financeiro` consegue acessar módulos não permitidos. |
