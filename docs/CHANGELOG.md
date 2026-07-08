# Changelog

Registro das mudanças relevantes por sessão de trabalho. Cada entrada documenta
o quê e o porquê; detalhes de implementação ficam no código e nas mensagens de
commit.

## 2026-07-08

### Navegação da bottom nav corrigida
Home, Profissionais, Carteirinha e Perfil implementavam cada uma sua própria
lógica de troca de aba (`push`/`pushReplacement`/`pop` misturados), causando
"pulos" para a tela errada. Todas agora usam
`AppNavigation.goToBottomNavIndex` (`lib/shared/widgets/app_navigation.dart`),
que reseta a pilha de rotas (`pushAndRemoveUntil`) a cada troca.

### "Médicos" → "Profissionais"
Título da listagem corrigido (`lib/features/professionals/presentation/pages/professionals_page.dart`).

### Feature Profissionais conectada ao backend real
Criada em Clean Architecture (`lib/features/professionals/{domain,data,presentation}`),
substituindo a lista mock por dados reais da tabela `professionals` (mesma
usada pelo admin), filtrando `is_active = true`. O filtro de especialidades
passou a ser montado a partir das especialidades realmente presentes nos
profissionais carregados.

### Perfil e Carteirinha sem mock
- `ProfilePage`: nome/e-mail/data de associação vêm do `ProfileBloc` real
  (antes eram `'Diana'` / `'diana23santos@gmail.com'` fixos).
- `CardPage`: nome e código do titular (usados no QR) vêm do `ProfileBloc`
  (nome e `id` reais). O "Histórico de uso" da carteirinha agora reaproveita
  o `ConsultationBloc` já existente — `ConsultationEntity`/`ConsultationModel`
  foram estendidos com `finalValue`/`discountPercentage` (colunas que já
  existiam em `consultations` mas nunca eram lidas de volta pro app).

### Card "assine agora" na Home com preço real
`NoPlanCard` (exibido quando o usuário não tem assinatura) agora busca o
plano mais barato ativo via `PlansSupabaseDataSource`, mostra o preço
("A partir de R$ X/período") e leva direto pra `PaymentPage` com esse plano
pré-selecionado — antes ia pra tela de escolha de planos sem mostrar valor.

### Auth não quebra mais em modo dev/mock
`AuthDataSource` era sempre `AuthSupabaseDataSource`, mesmo quando o Supabase
não estava inicializado (`main_dev.dart`), derrubando toda a árvore de DI.
Agora usa `AuthUnavailableDataSource` (já existia, não estava ligado) quando
`SupabaseConfig.isInitialized == false`.

### Tela de Pagamento (checkout)
- Removida a taxa fixa de R$ 4,99 (não deveria existir).
- Removido o formulário manual de cartão (nome/número/validade/CVV — nunca
  cobrava de verdade) e a opção redundante "Cartão via InfinitePay": agora
  existem só "Cartão de Crédito" (redireciona pro checkout da InfinitePay) e
  "Pix".
- Removido texto duplicado "Mensal Vita Mensal" no resumo do plano.

### InfinityPay: redirect_url inválido
A API de checkout da InfinityPay (`/links`) rejeita `redirect_url` com
esquema customizado (`vittaclube://...`) — exige URI http(s)
(`"redirect_url": ["is not a valid URI"]`). Criada Edge Function
`infinitypay-return` como página-ponte: recebe o retorno em HTTPS e responde
com um 302 puro (`Location: vittaclube://payment/infinitypay/return?...`).
Um bounce via HTML/`<script>` não funciona porque o gateway de Edge
Functions do Supabase injeta `Content-Security-Policy: sandbox` nas
respostas, bloqueando JS.

`app_config.dart` ganhou `resolvedInfinityPayRedirectUrl` (mesmo padrão do
`resolvedInfinityPayWebhookUrl`), apontando por padrão pra essa function.

**Limitação conhecida, ainda em aberto:** o endpoint `/links` da InfinityPay
usado aqui é de **link de pagamento avulso**, sem conceito de assinatura/
recorrência. Pagar uma vez ativa a assinatura por um período; não há
cobrança automática no período seguinte. A única cobrança recorrente de
verdade no projeto é o Pix Automático (Woovi). Decisão sobre se a
InfinityPay oferece alguma API de recorrência separada (com API key própria)
ainda depende de confirmação direta com o suporte deles.

### Bug de produção: contas novas sem perfil
O trigger `on_auth_user_created` (cria a linha em `public.profiles` no
signup) existia no dev mas **não existia no prod** — removido manualmente em
algum momento fora do histórico de migrations rastreado. Resultado: nenhuma
conta criada no prod desde então ganhou perfil (Google ou e-mail/senha),
quebrando saudação da Home, Carteirinha, Perfil e o checkout (violação de
FK em `payment_intents.user_id → profiles.id`).

Corrigido via `supabase/migrations/20260707000100_restore_new_user_trigger.sql`
(aplicada em dev e prod) + backfill manual das 3 contas de prod que já
existiam sem perfil.

### `app.encryption_key` ausente no prod
`encrypt_sensitive()` (usada para CPF/telefone no cadastro) depende de
`current_setting('app.encryption_key')`, vazia no prod — qualquer signup com
CPF/telefone falhava silenciosamente dentro do `EXCEPTION WHEN OTHERS` do
trigger. **Ainda não resolvido**: `ALTER DATABASE/ROLE ... SET` para essa
chave é bloqueado por permissão de plataforma mesmo via Studio (não é algo
que o dono do projeto consiga rodar por SQL direto). Caminho correto é
reescrever `encrypt_sensitive`/`decrypt_sensitive` para usar o Vault do
Supabase — ainda pendente.

### Migration `uuid_generate_v4()` quebrada no dev
`20260606000100_partner_applications.sql` dependia da extensão `uuid-ossp`,
habilitada no prod mas ausente no dev (projeto mais novo). Corrigido com
`supabase/migrations/20260606000050_enable_uuid_ossp.sql`.

### Tela "Pagar" sem mock
`PaymentsPage` (`lib/features/payments/presentation/pages/payments_page.dart`)
tinha plano, final de cartão, vencimento e histórico de pagamento
inteiramente hardcoded, e os botões "Pagar"/"Forma de Pagamento" não faziam
nada. Reescrita usando:
- `SubscriptionBloc` real para status/nível/vencimento.
- Nova feature `lib/features/payments/{domain,data,presentation}` lendo a
  tabela `payments` de verdade para o histórico.
- Botão "Forma de Pagamento" removido (não existe funcionalidade real por
  trás — não há cartão salvo no sistema hoje).

### Cancelamento de assinatura ligado de verdade
`CancellationReasonPage._handleContinue()` só mostrava um snackbar de
sucesso e fechava a tela, sem cancelar nada. Agora:
- Se a assinatura for Pix Automático (`pixStatus != none`), chama a Edge
  Function `cancel-woovi-subscription` — que **nunca era invocada pelo app**
  antes disso (bug real: cancelar no app não cancelava a recorrência no
  Woovi, o usuário continuaria sendo debitado).
- Caso contrário (pagamento avulso/cartão), usa o `CancelSubscriptionUseCase`
  já existente.
- Erros de cancelamento agora aparecem pro usuário (antes sempre "sucesso").

### Infra Supabase (dev + prod)
Migrations pendentes aplicadas nos dois projetos (incluindo as três acima:
`enable_uuid_ossp`, `restore_new_user_trigger`, e as que já estavam
pendentes há mais tempo: `partner_applications`, `harden_release_roles`,
`infinitypay_checkout_webhook`). Edge Functions deployadas:
`health-check`, `create-woovi-subscription`, `woovi-webhook`,
`reconcile-woovi-subscription`, `cancel-woovi-subscription`,
`infinitypay-webhook`, `infinitypay-return`. Scripts
`scripts/supabase_push_{dev,prod}.sh` atualizados para incluir a nova
function `infinitypay-return`.

### Limpeza de lint
`flutter analyze`: 34 → 0 issues. Variável e import não usados, cast
desnecessário, 20 usos de `withOpacity` (depreciado) trocados por
`.withValues(alpha:)`, 11 usos de `BuildContext` após gap assíncrono sem
checar `context.mounted`.
