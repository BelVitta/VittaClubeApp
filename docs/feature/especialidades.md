# Especialidades

Categorias médicas (Cardiologia, Pediatria, etc.) usadas para agrupar profissionais.

## O que faz
CRUD simples: nome, ícone, status.

## Fluxo
1. Admin cria especialidade → vira filtro na tela de profissionais.
2. Profissionais são vinculados a ≥1 especialidade.

## Permissão Admin
- ✅ Criar, editar, inativar.

## Permissão Super Admin
- ✅ Tudo + excluir (bloqueado se houver profissionais vinculados).

## Riscos (recepcionista)
- **Baixo**: dados públicos, sem valor financeiro.
- Risco operacional: renomear especialidade em uso pode confundir usuários.
- Mitigação: validar vínculos antes de excluir.

## RLS Supabase
- `SELECT`: público autenticado.
- `INSERT/UPDATE`: admin + financeiro.
- `DELETE`: apenas financeiro.
