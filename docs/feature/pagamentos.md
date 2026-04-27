# Pagamentos

Histórico e gestão de transações (mensalidades, planos).

## O que faz
Listar pagamentos, filtrar por status (pago/pendente/cancelado), ver detalhe, estornar.

## Fluxo
1. Usuário paga plano (gateway externo — Stripe/Pagar.me).
2. Webhook atualiza status no Supabase.
3. Admin consulta status para liberar atendimento.
4. Super Admin vê valores, faturamento, pode estornar.

## Permissão Admin (recepcionista) — ⚠️ LIMITADO
- ✅ Ver **status** (pago/pendente) de um usuário específico.
- ❌ **Não vê valores monetários** (R$ ocultos).
- ❌ Não lista relatório geral.
- ❌ Não estorna.

## Permissão Super Admin
- ✅ Tudo: valores, relatório por período, estorno, exportar CSV.

## Riscos (recepcionista) — ⚠️ CRÍTICO
- Dados financeiros + integração com gateway = **risco máximo**.
- Recepcionista com acesso a valores pode: vazar faturamento, estornar indevidamente, criar pagamento fake.
- Mitigação:
  - UI: admin vê só `status` (boolean), nunca `amount`.
  - RLS bloqueia `SELECT amount` para role=admin.
  - Estorno/criação manual: **somente financeiro**, com confirmação e 2FA recomendado.
  - Webhook do gateway valida assinatura HMAC.
  - `audit_log` em toda ação financeira.

## RLS Supabase
```sql
-- admin: só campos não-sensíveis
CREATE POLICY "admin_read_status" ON payments FOR SELECT
  USING (auth.jwt()->>'role' = 'admin')
  WITH CHECK (false); -- via VIEW sem amount
-- financeiro: tudo
CREATE POLICY "financeiro_all" ON payments FOR ALL
  USING (auth.jwt()->>'role' = 'financeiro');
```
