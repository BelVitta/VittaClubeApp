# Cupons

Cupons de desconto (percentual ou fixo) aplicáveis em planos/serviços.

## O que faz
Criar cupom (código, tipo, valor, validade, limite de uso), listar, aplicar manualmente em pagamento, desativar.

## Fluxo
1. Super Admin cria cupom "PROMO20" (20% off, 100 usos).
2. Usuário aplica no app ou admin aplica manualmente no balcão.
3. Sistema valida validade + limite + elegibilidade.

## Permissão Admin (recepcionista)
- ✅ Listar cupons ativos.
- ✅ Aplicar cupom existente em pagamento do usuário.
- ❌ Não cria, não edita valor/desconto.

## Permissão Super Admin
- ✅ Tudo: criar, editar, desativar, ver relatório de uso/ROI.

## Riscos (recepcionista) — ALTO (financeiro)
- Recepcionista criar cupom 100% = **fraude** (serviço grátis).
- Distribuir cupom a conhecidos.
- Mitigação:
  - Criação/edição: **apenas financeiro**.
  - Aplicação: admin só usa cupom já existente e ativo.
  - Log de aplicação: admin + user + cupom + timestamp.
  - Limite de desconto por aplicação (ex: admin não aplica cupom >50%).

## RLS Supabase
- `SELECT`: admin + financeiro + user (só cupons públicos).
- `INSERT/UPDATE/DELETE`: apenas financeiro.
- Aplicação: RPC `apply_coupon(code, payment_id)` valida tudo server-side.
