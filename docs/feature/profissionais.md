# Profissionais

Cadastro dos médicos/profissionais da clínica.

## O que faz
CRUD de profissionais: nome, CRM, especialidade, foto, status ativo/inativo, agenda.

## Fluxo
1. Admin abre lista → busca por nome/especialidade.
2. Cria/edita profissional → vincula a especialidade.
3. Profissional aparece na listagem do app do usuário.

## Permissão Admin (recepcionista)
- ✅ Criar, editar, ativar/inativar.
- ❌ Não pode excluir permanentemente (soft delete só).

## Permissão Super Admin
- ✅ Tudo do admin + hard delete + editar dados fiscais/comissão (se houver).

## Riscos de segurança (recepcionista)
- **Baixo**: dados públicos (nome, CRM já aparecem no app).
- **Médio**: pode inativar profissional errado e quebrar agenda.
- Mitigação: log de alterações (`audit_log`), confirmação ao inativar com consultas futuras agendadas.

## RLS Supabase
- `SELECT`: todos autenticados.
- `INSERT/UPDATE`: admin + financeiro.
- `DELETE`: apenas financeiro.
