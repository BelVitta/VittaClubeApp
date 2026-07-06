# Pix Automático Woovi - Fluxo funcional

## Objetivo

Controlar o acesso pago ao VittaClube por assinatura mensal recorrente de
R$34,90 via Pix Automático. O app Flutter apenas inicia a jornada, abre o link
do banco e lê o status local no Supabase. A Woovi nunca é chamada diretamente
pelo app.

## Estados principais

- `waiting_authorization`: contrato criado, aguardando aprovação no banco. Acesso bloqueado.
- `active`: assinatura paga e vigente. QR, benefícios, dependentes e agendamentos liberados.
- `payment_pending`: cobrança falhou e está em recuperação automática. Acesso continua liberado com aviso.
- `blocked`: cobrança não recuperada ou assinatura irregular. QR e benefícios bloqueados.
- `rejected`: autorização recusada ou abandonada no banco. Acesso bloqueado e usuário pode tentar novamente.
- `cancelled`: recorrência cancelada. Acesso permanece apenas até `current_period_end`.
- `expired`: período pago encerrado. Acesso bloqueado.

## Ativação

1. Usuário acessa a tela de assinatura.
2. App exibe preço, recorrência, ausência de teste grátis e aviso de saída para o banco.
3. App chama a Edge Function `create-woovi-subscription`.
4. Edge Function cria o contrato na Woovi e grava `waiting_authorization`.
5. App abre `paymentLinkUrl`.
6. Ao voltar do banco, o app não presume sucesso. Ele atualiza/lê o status no Supabase.
7. Webhook aprovado/pago muda a assinatura para `active`.

## Uso do clube

- QR da carteirinha só abre quando `canUseQr = true`.
- Dependentes e agendamentos só aparecem quando `canAccessBenefits = true`.
- Usuário bloqueado vê modal de restauração antes de qualquer uso protegido.

## Falha de cobrança

1. Webhook de tentativa rejeitada marca `payment_pending`.
2. App mostra aviso persistente.
3. Acesso segue liberado durante a janela de recuperação.
4. Webhook de cobrança paga volta para `active`.
5. Webhook de cobrança expirada/rejeitada final muda para `blocked`.

## Cancelamento

- Cancelamento vindo do banco ou operador muda status para `cancelled`.
- O acesso não deve ser removido antes do fim do período pago.
- Após o período, o acesso deve ser tratado como bloqueado/expirado.

## Checklist manual de fluxo

- Assinar abre a explicação antes do banco.
- O app exibe `Aguardando confirmação do seu banco` após criar contrato.
- O app não libera QR apenas porque voltou do banco.
- Status ativo mostra R$34,90 e próxima cobrança.
- Status pendente mostra aviso de recuperação por até 7 dias.
- Status bloqueado impede QR, dependentes e agendamento.
- Status cancelado mostra fim do período pago.

