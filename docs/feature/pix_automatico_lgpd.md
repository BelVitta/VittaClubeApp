# Pix Automático Woovi - Checklist LGPD

## Dados pessoais envolvidos

- Nome
- CPF/taxID
- E-mail
- Telefone
- Status de assinatura
- Histórico de cobrança e eventos de acesso

## Finalidade

Os dados são usados para criar autorização Pix Automático, identificar o titular,
controlar acesso ao clube, prestar suporte e auditar eventos financeiros.

## Minimização

- Flutter coleta apenas dados necessários para criar a autorização.
- Dados sensíveis financeiros e eventos completos ficam no Supabase.
- Payload de webhook deve ser usado para auditoria/suporte, não para exibição pública.

## Acesso

- Usuário visualiza somente a própria assinatura.
- Operadores devem ver apenas o necessário para atendimento.
- Dados financeiros detalhados devem ser restritos a `financeiro`/`super_admin`.

## Retenção e suporte

- Manter histórico de eventos de pagamento enquanto necessário para auditoria, suporte e contestação.
- Definir política operacional para exportação/exclusão de dados do usuário.
- Exclusão deve considerar obrigações legais/fiscais de registros financeiros.

## Checklist antes de entrega

- Política de privacidade menciona pagamento recorrente e tratamento de CPF/telefone.
- Tela de assinatura informa cobrança recorrente antes do banco.
- Suporte sabe explicar cancelamento pelo banco.
- Existe caminho para solicitar exportação/exclusão de dados.
- Dados de outro usuário não aparecem em tela comum.

