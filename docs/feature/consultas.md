# Consultas

Agendamento e gestão de consultas médicas.

## O que faz
Listar, criar, remarcar, cancelar, marcar como realizada. Filtros por data, profissional, status.

## Fluxo
1. Usuário agenda no app → consulta `pending`.
2. Admin confirma → `confirmed`.
3. Dia da consulta: valida QR do usuário, marca `completed`.
4. Cancelamento: seleciona motivo (ver `motivos_cancelamento.md`).

## Permissão Admin (recepcionista)
- ✅ Criar, confirmar, cancelar, remarcar, marcar realizada.
- ✅ Ver todas as consultas da clínica.

## Permissão Super Admin
- ✅ Tudo + relatório (taxa de no-show, consultas/profissional).

## Riscos (recepcionista) — MÉDIO
- Pode ver agenda cheia = mapa operacional da clínica.
- Pode cancelar consulta alheia.
- Mitigação:
  - `audit_log` em cancelamentos.
  - Notificação automática ao usuário quando admin cancela.
  - Validar que motivo de cancelamento foi informado.

## RLS Supabase
- `SELECT/INSERT/UPDATE`: admin + financeiro.
- `DELETE`: apenas financeiro (admin só muda status para `cancelled`).
