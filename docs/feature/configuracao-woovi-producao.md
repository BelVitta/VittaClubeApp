# Configuração da Woovi em produção — Vitta Clube

Este guia descreve a configuração quando existe somente uma conta Woovi de produção.

## Atenção antes de começar

Não coloque AppID, chaves ou segredos no chat, no Flutter ou no Git.

Existe uma pendência importante no código atual: a integração local ainda valida o webhook como HMAC, usando `WOOVI_WEBHOOK_SECRET`. A documentação atual da Woovi informa que o webhook usa `x-webhook-signature` com assinatura RSA-SHA256 e chave pública obtida pela API. A chave pública pode ser rotacionada.

Fontes oficiais:

- [Criar API/AppID](https://developers.woovi.com/en/docs/apis/api-getting-started)
- [Chaves públicas dos webhooks](https://developers.woovi.com/docs/webhook/seguranca/webhook-public-keys)
- [Criar webhooks](https://developers.woovi.com/docs/webhook/platform/webhook-platform-api)
- [Eventos do Pix Automático](https://developers.woovi.com/docs/pix-automatic/webhooks/pix-automatic-webhooks)

Por esse motivo, não cadastre o webhook de produção como etapa final ainda. Primeiro é necessário trocar a validação HMAC do projeto pela validação RSA oficial.

## 1. Criar o AppID de produção

1. Acesse o painel de produção da Woovi.
2. Abra `API/Plugins`.
3. Clique em `Nova API/Plugin`.
4. Escolha `API` — não escolha `Plugin`, pois a chamada será feita pelo backend Supabase.
5. Nome sugerido: `Vitta Clube Produção`.
6. Conclua o segundo fator de autenticação.
7. Copie o AppID e guarde-o somente em local seguro.

A API usa o AppID diretamente no header `Authorization`, sem o prefixo `Bearer`.

## 2. Preparar o arquivo local do projeto

Na raiz do projeto:

```bash
cp supabase.env.example supabase.env
```

Preencha somente no arquivo local:

```dotenv
SUPABASE_PROD_REF=seu_ref_do_projeto_supabase
SUPABASE_PROD_DB_PASSWORD=sua_senha_do_banco

WOOVI_PROD_ENVIRONMENT=production
WOOVI_PROD_BASE_URL=https://api.woovi.com
WOOVI_PROD_APP_ID=seu_app_id_de_producao
WOOVI_PROD_WEBHOOK_SECRET=

VITTACLUBE_SUBSCRIPTION_VALUE_CENTS=3490
VITTACLUBE_SUBSCRIPTION_INTERVAL=MONTHLY
VITTACLUBE_SUBSCRIPTION_JOURNEY=PAYMENT_ON_APPROVAL
VITTACLUBE_RETRY_POLICY=THREE_RETRIES_7_DAYS
```

Não faça commit desse arquivo. Ele já está listado no `.gitignore`.

O valor `3490` representa R$ 34,90. O preço também é validado no banco e na Edge Function.

## 3. Criar o webhook de produção

Depois que a validação RSA estiver corrigida no código, use esta URL:

```text
https://SEU_REF_PROD.supabase.co/functions/v1/woovi-webhook
```

No painel da Woovi, crie o webhook em `API/Plugins` ou na área de webhooks. Se o painel permitir somente um evento por webhook, crie um webhook para cada evento abaixo:

- `PIX_AUTOMATIC_APPROVED`
- `PIX_AUTOMATIC_REJECTED`
- `PIX_AUTOMATIC_COBR_CREATED`
- `PIX_AUTOMATIC_COBR_APPROVED`
- `PIX_AUTOMATIC_COBR_REJECTED`
- `PIX_AUTOMATIC_COBR_TRY_REJECTED`
- `PIX_AUTOMATIC_COBR_TRY_REQUESTED`
- `PIX_AUTOMATIC_COBR_COMPLETED`

A Woovi envia uma chamada de teste ao criar o webhook. O endpoint precisa responder HTTP 200 para o teste ser aceito. O endpoint do projeto também valida a assinatura antes de alterar qualquer dado.

## 4. O que ainda não fazer

Não execute ainda:

```bash
./scripts/supabase_push_prod.sh
```

Esse script aplica migrations e publica as Edge Functions em produção. Ele só deve ser executado depois de:

1. corrigir a validação RSA do webhook;
2. revisar os testes;
3. confirmar que o AppID foi colocado no `supabase.env` local;
4. confirmar que a URL do webhook está correta;
5. autorizar explicitamente o deploy de produção.

O script possui uma confirmação adicional e exige digitar `PUSH PROD`.

## 5. Teste mínimo após a correção

O primeiro teste deve ser controlado:

1. Criar uma conta de teste no aplicativo.
2. Iniciar uma assinatura mensal de R$ 34,90.
3. Autorizar o Pix Automático no banco compatível.
4. Confirmar que a Woovi envia `PIX_AUTOMATIC_APPROVED` e `PIX_AUTOMATIC_COBR_COMPLETED`.
5. Confirmar no Supabase que a assinatura fica `active` somente após a cobrança concluída.
6. Confirmar que o QR e os benefícios continuam bloqueados enquanto estiver `waiting_authorization`.
7. Confirmar o registro de uma única cobrança.
8. Cancelar a assinatura e confirmar que novas cobranças são interrompidas, mantendo o acesso até o fim do período pago.

Não use usuários reais para o primeiro teste de produção. Como não há sandbox disponível, o teste de produção deve ser feito com uma conta controlada, valor e dados conferidos.

## 6. Checklist antes do deploy

- [ ] AppID de produção criado como `API`.
- [ ] AppID guardado somente no `supabase.env` local.
- [ ] Projeto Supabase de produção identificado.
- [ ] Senha do banco de produção preenchida localmente.
- [ ] Validação RSA do webhook implementada e testada.
- [ ] URL pública do webhook cadastrada na Woovi.
- [ ] Eventos do Pix Automático configurados.
- [ ] Teste de webhook respondido com HTTP 200.
- [ ] Migrations revisadas.
- [ ] Edge Functions revisadas.
- [ ] Teste controlado de criação, aprovação, renovação e cancelamento planejado.
- [ ] Autorização explícita para executar `PUSH PROD`.

## Estado atual do projeto

O projeto já possui:

- `create-woovi-subscription`;
- `woovi-webhook`;
- `reconcile-woovi-subscription`;
- `cancel-woovi-subscription`;
- scripts separados para deploy dev e produção;
- suporte ao plano mensal de R$ 34,90.

O bloqueio atual é a adaptação do validador de webhook HMAC para o modelo RSA documentado pela Woovi. Depois dessa adaptação, a próxima etapa é configurar a URL e fazer o deploy controlado em produção.
