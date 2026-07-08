# Security & Permissions Contract: Vitta Clube

## Roles

### user

Cliente/membro.

**Can**:

- ver e editar proprio perfil permitido;
- ver propria assinatura, nivel, carteirinha e historico;
- ver planos, profissionais, parceiros, sorteios e cupons elegiveis;
- iniciar pagamento, contato, agendamento e validacao de beneficio;
- solicitar exportacao/exclusao de dados conforme politica.

**Cannot**:

- ver dados de outros usuarios;
- alterar roles;
- acessar relatorios;
- executar sorteios;
- criar cupons ou alterar precos.

### admin

Recepcionista/operador.

**Can**:

- gerenciar profissionais, especialidades e consultas;
- buscar usuario com dados mascarados;
- validar carteirinha;
- ver status operacional de pagamento;
- aplicar cupom ativo conforme regra;
- criar/editar dados operacionais permitidos.

**Cannot**:

- ver valores financeiros consolidados;
- alterar role;
- excluir usuario permanentemente;
- alterar precos de planos;
- criar cupons;
- executar sorteios;
- acessar CPF/telefone completo se nao for necessario.

### financeiro/super_admin

Dono/gestor.

**Can**:

- gerenciar roles e admins;
- gerenciar planos, precos, cupons, parceiros e sorteios;
- ver relatorios financeiros;
- exportar dados permitidos;
- executar acoes criticas com auditoria.

### parceiro

Parceiro/laboratorio quando habilitado.

**Can**:

- ver e editar dados do proprio parceiro;
- gerenciar proprios servicos quando autorizado;
- ver validacoes do proprio parceiro;
- validar desconto conforme metodo aprovado.

**Cannot**:

- ver dados financeiros da clinica;
- ver dados de outros parceiros;
- alterar descontos globais;
- acessar dados sensiveis de clientes alem do necessario para validacao.

## RLS Requirements

- Toda tabela sensivel deve ter RLS habilitado.
- Policies devem usar role do token e ownership.
- Admin deve acessar views mascaradas quando houver dados pessoais/financeiros.
- Operacoes criticas devem ocorrer por RPC ou regra server-side, nao por logica
  apenas no cliente.

## Server-Side Validation Required

- alteracao de role;
- criacao/edicao de plano e preco;
- aplicacao de cupom;
- execucao de sorteio;
- confirmacao/estorno de pagamento;
- validacao de desconto em parceiro;
- cancelamento/remarcacao de consulta com impacto no cliente.

## Audit Log Required

Registrar actor, role, entity, action, timestamp e metadados minimos para:

- role changes;
- plan price changes;
- coupon create/update/apply;
- draw execute/cancel/manual winner;
- payment refund/manual update;
- consultation cancel/reschedule/complete;
- partner code regenerate;
- user deactivate/delete/export.

## Secrets

- Segredos nao entram no repositorio.
- Usar arquivos example para estrutura e variaveis reais por ambiente.
- Links externos devem usar `url_launcher` com validacao de scheme e fallback.

## LGPD

- Consentimento explicito para termos e privacidade.
- Possibilidade de solicitar exportacao e exclusao de dados.
- Minimizar exibicao de dados pessoais.
- Mascarar CPF/telefone/endereco para roles sem necessidade operacional.
- Registrar auditoria para acesso/alteracao sensivel quando aplicavel.
