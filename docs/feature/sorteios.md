# Sorteios

Campanhas promocionais (ex: "sorteio de R$ 500 entre membros ativos").

## O que faz
Criar sorteio, definir regras (elegibilidade, prêmio, data), listar participantes, rodar sorteio, declarar vencedor.

## Fluxo
1. Super Admin cria sorteio com regras.
2. Usuários elegíveis aparecem automaticamente.
3. Data do sorteio: função random no backend seleciona vencedor.
4. Notificação ao vencedor + registro público.

## Permissão Admin (recepcionista) — ⚠️ RESTRITO
- ✅ Visualizar sorteios ativos e vencedores.
- ❌ Não cria, não roda sorteio, não edita regras.

## Permissão Super Admin
- ✅ Tudo: criar, editar regras, executar sorteio, declarar vencedor manualmente (com justificativa).

## Riscos (recepcionista) — ALTO
- Fraude: manipular vencedor = prejuízo financeiro + reputação.
- Por isso, **operação é exclusiva do financeiro**.
- Sorteio aleatório deve ser feito via **RPC no Postgres** (função `SECURITY DEFINER`), não no cliente.
- `audit_log` imutável da execução (seed + timestamp + lista de elegíveis).

## RLS Supabase
- `SELECT`: admin + financeiro.
- `INSERT/UPDATE/DELETE`: apenas financeiro.
- Execução do sorteio: RPC `draw_winner(draw_id)` com `SECURITY DEFINER` + check de role.
