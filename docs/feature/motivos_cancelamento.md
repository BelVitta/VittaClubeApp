# Motivos de Cancelamento

Lista fixa de motivos usados ao cancelar consulta (ex: "Paciente não compareceu", "Profissional indisponível").

## O que faz
CRUD simples. Usado como dropdown na tela de cancelamento de consulta.

## Fluxo
1. Super Admin cadastra motivos padrão.
2. Admin seleciona motivo ao cancelar consulta.
3. Estatísticas usam esses motivos para relatório.

## Permissão Admin (recepcionista)
- ✅ Ler lista (usar no cancelamento).
- ❌ Não cria, não edita.

## Permissão Super Admin
- ✅ CRUD completo.

## Riscos (recepcionista) — BAIXO
- Se admin pudesse editar, poderia mascarar motivos reais e distorcer relatório.
- Por isso é read-only para admin.

## RLS Supabase
- `SELECT`: admin + financeiro.
- `INSERT/UPDATE/DELETE`: apenas financeiro.
