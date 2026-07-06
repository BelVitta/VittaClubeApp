# Pix Automático Woovi - Webhooks e idempotência

## Regra central

Todo webhook deve ser validado por HMAC usando o corpo bruto antes de alterar
qualquer dado financeiro. Evento inválido retorna erro e não muda assinatura,
cobrança ou acesso.

## Pipeline esperado

1. Receber corpo bruto.
2. Validar assinatura/HMAC.
3. Normalizar evento Woovi.
4. Inserir `event_id` em `woovi_webhook_events`.
5. Se `event_id` já existir, retornar sucesso com `deduplicated = true`.
6. Processar efeito de negócio.
7. Marcar evento como `processed` ou `failed`.

## Eventos mínimos

- `OPENPIX:SUBSCRIPTION_CREATED`: marca `waiting_authorization`.
- `OPENPIX:SUBSCRIPTION_AUTHORIZED`: marca autorização aprovada.
- `OPENPIX:SUBSCRIPTION_REJECTED`: bloqueia e permite tentar novamente.
- `OPENPIX:SUBSCRIPTION_CANCELLED`: cancela recorrência sem apagar período pago.
- `OPENPIX:CHARGE_CREATED`: cria/atualiza cobrança.
- `OPENPIX:CHARGE_COMPLETED`: marca cobrança paga e assinatura ativa.
- `PIX_AUTOMATIC_COBR_TRY_REJECTED`: marca pendência com aviso.
- `PIX_AUTOMATIC_COBR_REJECTED` ou cobrança expirada: bloqueia após recuperação.

## Auditoria

Mudanças reais de status/acesso devem gravar `subscription_access_events` com:

- assinatura
- usuário
- status anterior e novo
- acesso anterior e novo
- motivo
- origem `woovi_webhook`
- event id e tipo

## Casos para testar manualmente/sandbox

- Mesmo webhook enviado duas vezes não duplica período.
- Falha de cobrança enviada duas vezes não duplica aviso/auditoria.
- Cobrança paga após falha volta para `active`.
- Cancelamento preserva `current_period_end`.
- Webhook sem HMAC válido não altera nada.

