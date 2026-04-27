# Features do Painel Admin — Vita Clube

Documentação resumida de cada feature do painel administrativo, com foco em **fluxo**, **papel (admin/recepcionista vs super admin/financeiro)** e **riscos de segurança**.

## Papéis
- **Admin (recepcionista)**: operação diária — cadastros, validação, agenda.
- **Super Admin (financeiro)**: tudo do admin + valores de venda, planos, badges, gestão de admins.

## Índice

| Feature | Admin | Super Admin | Doc |
|---------|:-----:|:-----------:|-----|
| Profissionais | ✅ | ✅ | [profissionais.md](profissionais.md) |
| Especialidades | ✅ | ✅ | [especialidades.md](especialidades.md) |
| Usuários | ✅ (ler/editar) | ✅ (excluir, criar admin) | [usuarios.md](usuarios.md) |
| Pagamentos | ⚠️ só status | ✅ valores/relatório | [pagamentos.md](pagamentos.md) |
| Consultas | ✅ | ✅ | [consultas.md](consultas.md) |
| Notificações | ✅ | ✅ | [notificacoes.md](notificacoes.md) |
| Sorteios | ⚠️ só visualizar | ✅ criar/sortear | [sorteios.md](sorteios.md) |
| Cupons | ✅ aplicar | ✅ criar/editar | [cupons.md](cupons.md) |
| Scanner QR | ✅ | ✅ | [scanner_qr.md](scanner_qr.md) |
| Motivos Cancelamento | ⚠️ só ler | ✅ editar | [motivos_cancelamento.md](motivos_cancelamento.md) |
| **Super Admin (extras)** | ❌ | ✅ | [super_admin.md](super_admin.md) |

## Princípio de segurança
Toda restrição é aplicada **na RLS do Supabase** (não apenas na UI). A UI esconde; a RLS bloqueia.
