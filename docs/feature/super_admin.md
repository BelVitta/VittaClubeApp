# Super Admin (role: financeiro)

Funcionalidades exclusivas do dono/gestor. Herda **todas** as permissões do admin + extras abaixo.

## Extras exclusivos

### 1. Gestão de Planos
- CRUD de planos (nome, preço, benefícios, duração).
- **Alterar preço afeta novos pagamentos**; contratos ativos mantêm valor antigo.
- Local: `admin/presentation/pages/plans/`.

### 2. Gestão de Badges
- Criar/editar sistema de gamificação (níveis, conquistas, recompensas).
- Local: `admin/presentation/pages/badges/`.

### 3. Gestão de Admins
- Criar novo usuário com role=`admin`.
- Revogar acesso.
- Obrigatório: log + 2FA recomendado.

### 4. Visualização financeira
- **Valores** em Pagamentos (admin vê só status).
- Relatórios: faturamento mensal, ticket médio, churn, ROI de cupons.
- Exportar CSV.

### 5. Operações sensíveis
- Estorno de pagamento.
- Execução de sorteio.
- Criação/edição de cupons.
- Broadcast de notificação para "todos".
- Hard delete de registros.

### 6. Auditoria
- Acesso ao `audit_log` completo (quem fez o quê, quando).
- Fundamental para LGPD e rastreio de fraude.

## Segurança do Super Admin
- **2FA obrigatório** (TOTP via Supabase Auth MFA).
- Sessão curta (ex: 1h de inatividade → re-login).
- IP allowlist opcional (configurável em produção).
- Notificação de login suspeito (novo dispositivo/localização).
- Role `financeiro` só é atribuível via SQL direto (não via UI) — blindagem final.

## RLS Supabase (padrão do role)
```sql
-- macro: financeiro tem bypass em quase tudo
CREATE POLICY "financeiro_full" ON <tabela>
  FOR ALL USING (auth.jwt()->>'role' = 'financeiro');
```

## Checklist para produção
- [ ] MFA habilitado no Supabase
- [ ] `audit_log` com trigger em todas tabelas sensíveis
- [ ] RLS revisada por tabela (nenhuma sem policy)
- [ ] Webhook do gateway com verificação HMAC
- [ ] Backup automático + teste de restore
- [ ] Monitoramento de tentativas de escalação de privilégio
