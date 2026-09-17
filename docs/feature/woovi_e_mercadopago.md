# Woovi (PIX Automático) + Mercado Pago (cartão)

Como terminar a cobrança do Vitta Clube: **PIX recorrente na Woovi**, **cartão no Mercado Pago**.

Não misturar os dois no mesmo botão. A API de Assinaturas do Mercado Pago **não** é Pix Automático do Banco Central.

---

## 1. Duas contas Woovi (dev vs normal)

A Woovi **não** é um toggle “sandbox” dentro da mesma conta. São **dois ambientes isolados**. Login, AppID, webhook e cobranças **não cruzam**.

Fonte: [Ambiente de teste Woovi](https://developers.woovi.com/docs/test-environment) e [API](https://developers.woovi.com/en/api).

| | Conta de **dev** (sandbox) | Conta **normal** (produção) |
|---|---|---|
| Painel | [app.woovi-sandbox.com](https://app.woovi-sandbox.com/) | [app.woovi.com](https://app.woovi.com) |
| API | `https://api.woovi-sandbox.com` | `https://api.woovi.com` |
| Cadastro | **Registrar de novo** no sandbox | Conta PJ real, banco recebedor |
| AppID | Gerado **só** no painel sandbox | Gerado **só** no painel produção |
| Dinheiro | Fake / simulado | Pix real |
| QR no app do banco | Em geral **não** é BR Code válido | QR real, autoriza no banco do cliente |
| Como “pagar” | Simular pagamento no painel da cobrança | Cliente autoriza no banco |
| Dados | Não usa dados da conta produção | Não usa AppID/webhook do sandbox |

Aviso oficial: **“Os dados de produção não funcionam no ambiente de testes.”** Quem já tem conta em `app.woovi.com` **precisa criar outra** em `app.woovi-sandbox.com`. Mesmo e-mail não replica AppID, empresa nem webhooks.

No Vitta Clube:

- Staging / testes → secrets **sandbox**
- `main_prod` / Play Store → secrets **produção**

Nunca um AppID de um ambiente na API do outro (`appID inválido`).

### Não confundir: “conta bancária de teste” dentro da produção

A Woovi também tem [conta bancária de teste](https://developers.woovi.com/docs/test/test-company-account) **dentro** do painel (às vezes o de produção): `Ajustes → Pix → Criar uma conta bancária de teste`.

Isso **não** é a conta de dev.

| | Sandbox (`app.woovi-sandbox.com`) | Conta bancária de teste (no painel) |
|---|---|---|
| O que é | Plataforma inteira de homologação | Banco virtual fake **numa** empresa |
| API | `api.woovi-sandbox.com` | Continua `api.woovi.com` se estiver na prod |
| Uso | Integrar o app sem Pix real | Simular cobrança/QR no painel |
| Pagar | Simular no detalhe da cobrança | Idem; QR **não** lê no banco de verdade |
| Webhook | `account.environment = TESTING` | Mesmo campo `TESTING` vs `PRODUCTION` |

Para o Vitta Clube: **integração = sandbox + AppID sandbox**. Conta bancária de teste na produção **não** substitui o ambiente de dev.

Pix Automático em sandbox: [documentação](https://developers.woovi.com/docs/tags/sandbox). Jornada do app: `PAYMENT_ON_APPROVAL` (jornada 3) — ao ler o QR o cliente **paga a 1ª parcela e autoriza** a recorrência. Docs: [como criar](https://developers.woovi.com/docs/pix-automatic/pix-automatic-how-to-create), [passo a passo](https://developers.woovi.com/docs/pix-automatic/pix-automatic-step-by-step).

---

## 2. O que o repo já tem (e o que o usuário ainda não vê)

| Peça | Estado |
|---|---|
| `create-woovi-subscription` | Cria contrato `PIX_RECURRING` na Woovi |
| `woovi-webhook` | HMAC + idempotência + status da assinatura |
| `reconcile-woovi-subscription` | Consulta a Woovi se o webhook falhar |
| `cancel-woovi-subscription` | Já chamado ao cancelar plano Pix Automático |
| `BillingProfilePage` / `PixAutomaticExplanationPage` | Telas existem, **checkout não navega até elas** |
| Botão PIX em `PaymentPage` | Mock / bloqueado em prod — **não chama a Woovi** |
| Secrets no `supabase_push_*.sh` | Só InfinitePay; **Woovi ainda não** |
| `woovi-webhook` sem JWT | Falta `verify_jwt = false` (hoje só o da InfinitePay tem) |

Configurar o painel **sozinho não libera o PIX no app**. Depois dos secrets, falta o fio no checkout (código).

Fluxo alvo:

```text
Escolher plano
  → Dados de cobrança (CPF, telefone, endereço)
  → Explicação R$ 34,90 / mês
  → Edge Function create-woovi-subscription
  → Abrir paymentLinkUrl no banco
  → Voltar e ler subscriptions no Supabase
     (não liberar QR só porque o usuário voltou)
```

O app **nunca** chama a Woovi. Só Edge Functions. AppID e webhook secret **não** entram no Flutter.

---

## 3. Checklist sandbox (fazer primeiro)

### 3.1 Conta de dev

1. Abrir [app.woovi-sandbox.com](https://app.woovi-sandbox.com/) e **cadastrar de novo**.
2. Completar empresa no sandbox (pode ser dados de teste).
3. Confirmar que Pix Automático aparece no painel / API de subscriptions.

### 3.2 AppID sandbox

1. **API/Plugins → Nova API/Plugin** → tipo **API** (não Plugin JS).
2. Nome: `vittaclube-sandbox`.
3. Copiar o **AppID**. Header `Authorization` = AppID **cru**, **sem** `Bearer`.
   Docs: [Começando](https://developers.woovi.com/docs/apis/api-getting-started).
4. Guardar no gerenciador de senhas. Não commitar.

### 3.3 Webhook sandbox

URL (ref do projeto **dev** no Supabase):

```text
https://<SUPABASE_DEV_REF>.supabase.co/functions/v1/woovi-webhook
```

Eventos mínimos ([webhooks Pix Automático](https://developers.woovi.com/docs/pix-automatic/webhooks/pix-automatic-webhooks)):

- `PIX_AUTOMATIC_APPROVED`
- `PIX_AUTOMATIC_REJECTED`
- `PIX_AUTOMATIC_COBR_CREATED`
- `PIX_AUTOMATIC_COBR_COMPLETED`
- `PIX_AUTOMATIC_COBR_REJECTED`
- `PIX_AUTOMATIC_COBR_TRY_REJECTED`

O código também aceita `OPENPIX:SUBSCRIPTION_*` e `OPENPIX:CHARGE_*`.

O endpoint valida **HMAC SHA-256 do corpo cru** em:

- `x-webhook-signature`
- `X-Woovi-Signature`
- `X-OpenPix-Signature`

O secret do painel = `WOOVI_WEBHOOK_SECRET` no Supabase.

**Obrigatório:** a Woovi **não envia JWT**. Deploy:

```bash
supabase functions deploy woovi-webhook --no-verify-jwt
```

E em `supabase/config.toml`:

```toml
[functions.woovi-webhook]
verify_jwt = false
```

Sem isso o POST morre no gateway do Supabase **antes** do HMAC.

### 3.4 Secrets no Supabase **dev**

```bash
supabase link --project-ref "$SUPABASE_DEV_REF"

supabase secrets set \
  WOOVI_ENVIRONMENT=sandbox \
  WOOVI_BASE_URL=https://api.woovi-sandbox.com \
  WOOVI_APP_ID="<app-id-sandbox>" \
  WOOVI_WEBHOOK_SECRET="<mesmo-secret-do-webhook-sandbox>" \
  VITTACLUBE_SUBSCRIPTION_VALUE_CENTS=3490 \
  VITTACLUBE_SUBSCRIPTION_INTERVAL=MONTHLY \
  VITTACLUBE_SUBSCRIPTION_JOURNEY=PAYMENT_ON_APPROVAL \
  VITTACLUBE_RETRY_POLICY=THREE_RETRIES_7_DAYS
```

Deploy das functions de cobrança:

```bash
supabase functions deploy create-woovi-subscription
supabase functions deploy reconcile-woovi-subscription
supabase functions deploy cancel-woovi-subscription
supabase functions deploy woovi-webhook --no-verify-jwt
```

### 3.5 Teste sem o app

JWT de um usuário logado no Supabase **dev**:

```bash
curl -X POST "https://<SUPABASE_DEV_REF>.supabase.co/functions/v1/create-woovi-subscription" \
  -H "Authorization: Bearer <JWT>" \
  -H "Content-Type: application/json" \
  -d '{
    "planId": "<id-do-plano-mensal>",
    "customer": {
      "name": "Teste Sandbox",
      "taxID": "31324227036",
      "email": "teste@email.com",
      "phone": "5511999999999",
      "address": {
        "zipcode": "01310100",
        "street": "Av Paulista",
        "number": "1000",
        "neighborhood": "Bela Vista",
        "city": "Sao Paulo",
        "state": "SP"
      }
    }
  }'
```

Esperado: `paymentLinkUrl` + status `waiting_authorization`.

No sandbox, abrir a cobrança/assinatura no painel e **simular pagamento / autorização** (o QR em geral **não** funciona no banco real). O webhook deve mudar `subscriptions` para `active`. Sem webhook o QR do clube **nunca** libera.

---

## 4. Checklist produção (conta normal)

Só depois do sandbox ponta a ponta.

1. Conta em [app.woovi.com](https://app.woovi.com) com **CNPJ**, conta bancária **real** aprovada, Pix Automático habilitado (exigência BC: empresa ativa).
2. **Outro** AppID: `vittaclube-prod`.
3. **Outro** webhook:

```text
https://<SUPABASE_PROD_REF>.supabase.co/functions/v1/woovi-webhook
```

4. Secrets no projeto **prod**:

```bash
supabase link --project-ref "$SUPABASE_PROD_REF"

supabase secrets set \
  WOOVI_ENVIRONMENT=production \
  WOOVI_BASE_URL=https://api.woovi.com \
  WOOVI_APP_ID="<app-id-producao>" \
  WOOVI_WEBHOOK_SECRET="<secret-webhook-producao>" \
  VITTACLUBE_SUBSCRIPTION_VALUE_CENTS=3490 \
  VITTACLUBE_SUBSCRIPTION_INTERVAL=MONTHLY \
  VITTACLUBE_SUBSCRIPTION_JOURNEY=PAYMENT_ON_APPROVAL \
  VITTACLUBE_RETRY_POLICY=THREE_RETRIES_7_DAYS
```

5. Redeploy das mesmas functions no projeto prod (`woovi-webhook` com `--no-verify-jwt`).
6. Primeiro teste com valor real baixo ou o R$ 34,90, **autorizando no app do banco**.

Valor da mensalidade **não** vem do app: a function usa `VITTACLUBE_SUBSCRIPTION_VALUE_CENTS` (3490).

---

## 5. Código que ainda falta (Woovi no checkout)

Fazer depois dos secrets sandbox:

1. PIX em `PaymentPage` = fluxo Woovi (não mock / `UnimplementedPaymentGateway`).
2. `createPixAutomaticSubscription` → `functions.invoke('create-woovi-subscription')` (hoje só insere linha local).
3. Navegar: plano → `BillingProfilePage` → `PixAutomaticExplanationPage` → link do banco.
4. Ao voltar: `refreshSubscriptionStatus` / `LoadCurrentSubscription`. Acesso só com status local `active` ou `payment_pending`.
5. `verify_jwt = false` no `woovi-webhook` (config + script).
6. `supabase_push_dev.sh` / `supabase_push_prod.sh` gravarem secrets Woovi (como já fazem com InfinitePay).

Cancelamento Pix Automático **já** chama `cancel-woovi-subscription`.

---

## 6. Mercado Pago — só cartão

[Assinaturas MP](https://www.mercadopago.com.br/developers/pt/docs/subscriptions/overview) (`/preapproval`) cobram de novo no **cartão tokenizado** (`card_token_id`). PIX no checkout do 1º ciclo **não** é débito Pix Automático nos meses seguintes.

No Vitta Clube:

| Botão | Provedor |
|---|---|
| PIX (recorrente) | Woovi Pix Automático |
| Cartão | Mercado Pago |

InfinitePay pode ficar no código até o 1º pagamento MP em sandbox confirmar; depois o botão cartão aponta só para o MP.

### 6.1 Conta MP

1. Conta vendedor + aplicação em [Suas integrações](https://www.mercadopago.com.br/developers/panel/app).
2. Credenciais **teste** (`TEST-…` / `APP_USR-…` de teste) vs **produção** — também **não misturar**.
3. Access Token **somente** em secret de Edge Function (`MP_ACCESS_TOKEN`). Nunca no Flutter.

### 6.2 Integração sugerida (Checkout Pro)

Igual ao redirect da InfinitePay:

1. Edge Function `create-mercadopago-preference` (JWT do usuário).
2. Cria preferência com valor do plano, `external_reference` = `user_id` + `plan_id`.
3. `back_urls` / deep link já existente: `vittaclube://payment/...`.
4. Webhook `https://<REF>.supabase.co/functions/v1/mercadopago-webhook` com `verify_jwt = false`.
5. Evento `payment` approved → grava `payments` e ativa `subscriptions` **sem** preencher `woovi_subscription_id`.
6. `PaymentPage` cartão abre o `init_point` do MP, não a InfinitePay.

Recorrência automática no **cartão** (cobrar todo mês sem o usuário voltar) é fase 2: Assinaturas MP com cartão salvo. O PIX mensal continua Woovi.

### 6.3 Secrets MP

Sandbox / teste:

```bash
supabase secrets set \
  MP_ACCESS_TOKEN="<token-teste>" \
  MP_WEBHOOK_SECRET="<secret-webhook-teste>" \
  MP_ENVIRONMENT=sandbox
```

Produção: tokens de produção no projeto prod.

---

## 7. Ordem de execução

1. Criar conta em **app.woovi-sandbox.com** (mesmo tendo conta em app.woovi.com).
2. AppID + webhook sandbox → secrets no Supabase **dev**.
3. Deploy functions; `woovi-webhook --no-verify-jwt`.
4. `curl` em `create-woovi-subscription` + simular pagamento no painel.
5. Código: ligar checkout PIX à function (passo 5 desta lista no código).
6. Um fluxo no app staging: autorizar → `subscriptions.status = active` → QR libera.
7. Conta **normal** Woovi + secrets **prod** + teste com Pix real.
8. Mercado Pago teste: function + botão cartão.
9. MP produção.
10. Play Store só com `main_prod` + secrets prod.

---

## 8. Referências

Woovi:

- [Ambiente de teste (conta de dev)](https://developers.woovi.com/docs/test-environment)
- [API prod vs sandbox](https://developers.woovi.com/en/api)
- [Criar AppID](https://developers.woovi.com/docs/apis/api-getting-started)
- [Conta bancária de teste (não é sandbox)](https://developers.woovi.com/docs/test/test-company-account)
- [Pix Automático — criar](https://developers.woovi.com/docs/pix-automatic/pix-automatic-how-to-create)
- [Passo a passo + webhooks](https://developers.woovi.com/docs/pix-automatic/pix-automatic-step-by-step)
- [Eventos Pix Automático](https://developers.woovi.com/docs/pix-automatic/webhooks/pix-automatic-webhooks)
- [Máquina de estados](https://developers.woovi.com/docs/pix-automatic/pix-automatic-state-machine)

Mercado Pago:

- [Assinaturas (cartão, não Pix Automático)](https://www.mercadopago.com.br/developers/pt/docs/subscriptions/overview)
- [Pagamentos automáticos (card on file)](https://www.mercadopago.com.br/developers/pt/docs/automatic-payments/overview)

Repo:

- `docs/feature/pix_automatico_env.md`
- `docs/feature/pix_automatico_fluxo.md`
- `docs/feature/pix_automatico_webhooks.md`
- `supabase/functions/_shared/woovi/`
- `scripts/supabase_push_dev.sh` / `supabase_push_prod.sh`
