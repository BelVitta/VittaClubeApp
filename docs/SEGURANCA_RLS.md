# Subir SQL em prod, RLS e riscos de segurança

## 1. Script para produção

Sim. Na raiz do repo:

```bash
# 1) Credenciais locais (não commitar)
# supabase.env precisa de:
#   SUPABASE_PROD_REF
#   SUPABASE_PROD_DB_PASSWORD

./scripts/supabase_push_prod.sh
```

O script pede para digitar `PUSH PROD`, faz `supabase link`, `supabase db push --include-all --yes` (todas as migrations em `supabase/migrations/`) e publica as Edge Functions (Woovi + InfinityPay).

Atalhos:

| Script | O que faz |
|---|---|
| `./scripts/supabase_push_dev.sh` | Migrations + functions no projeto **dev** |
| `./scripts/supabase_push_prod.sh` | Idem em **prod**, com confirmação |
| `./scripts/supabase_push_all.sh` | Dev primeiro; prod só se você digitar `PUSH PROD` de novo |

Documentação: [SUPABASE_COMMANDS.md](./SUPABASE_COMMANDS.md).

**Não** rode `schema.sql` inteiro em prod — isso é dump de referência. Prod só via **migrations**. As que o clube precisa agora incluem:

- `20260826000050_create_partners_tables.sql` (cria `public.partners`)
- `20260826000100_loyalty_mvp_partner_validation.sql`
- `20260827000100_cancellation_reasons_financeiro.sql`

Se o `db push` falhar por histórico remoto vs local, o próprio script indica `supabase migration list` e `migration repair`.

Staging ainda aponta para o **mesmo** projeto de prod (`AppConfig.initStaging` + [SETUP_DEV_PROD.md](./SETUP_DEV_PROD.md)). Empurrar “só staging” pode ser empurrar **produção**.

---

## 2. Auth vs autorização — o que está certo

O app usa **Supabase Auth** (JWT). O cliente só tem a **anon key**. Quem manda é **RLS + RPC SECURITY DEFINER** que checam `auth.uid()` e `profiles.role`. Isso é o desenho certo.

Já está razoavelmente sólido:

- INSERT de `profiles` só `id = auth.uid()` e `role = user`
- Usuário comum **não** muda `role`, `status`, `member_code`, CPF/telefone pelo UPDATE direto (trigger)
- Só financeiro muda `role` (`prevent_non_financeiro_role_change`)
- CPF/telefone via RPC, crypto **revogada** de `anon`/`authenticated`
- `validate_member_qr` / `validate_loyalty_card` exigem `auth.uid() = p_actor_user_id`
- Segredo do QR de dependente **não** é legível em `clinic_settings` pelo cliente
- Webhook Woovi valida HMAC
- Correção de indicação só financeiro, auditada, sem UPDATE direto na tabela

Login no app **não** é Firebase Auth de usuários. Google só entrega id token para o Supabase.

---

## 3. RLS para rever agora (prioridade)

`is_admin()` no banco **inclui `financeiro`**. Qualquer policy `USING (is_admin())` vale para recepção **e** superadmin. A UI esconde; o Postgrest **não**.

| Tabela / policy | Problema | O que deveria ser |
|---|---|---|
| `partners` — `Admins can manage partners` (`is_admin()`) | Recepção autenticada pode **CRUD parceiro e %** via API, mesmo sem a tela | `ALL` só `is_financeiro()`. Admin no máximo `SELECT` |
| `partner_services` — `Admins can manage` | Idem para preços de exame | Só parceiro dono + financeiro |
| `partner_validations` — `Admins can manage` | Recepção pode apagar/inventar validação de lab | Admin `SELECT`; insert só via RPC |
| `partner_validations` — `Parceiros can insert own validations` | Parceiro pode **INSERT direto** (nome/economia falsos) e pular `confirm_partner_validation` | Remover INSERT de cliente; só a RPC SECURITY DEFINER |
| `partners` — `Parceiros can update own partner` | Pode mudar nome, `is_active`, categoria. `%` está no trigger; o resto não | UPDATE limitado (logo/endereço) ou só financeiro ativa/desativa |
| `GRANT … ON partners TO authenticated` | Privilege de tabela amplo; RLS segura, mas é superfície extra | `GRANT SELECT` (+ insert só se RPC não bastar) |
| `coupons` / `draws` — `Admins can manage` | Recepção cria cupom e sorteio pelo Postgrest | Alinhar com a regra de negócio (sorteio real: quem executa o sorteio) |
| `payments` — `Admins can manage all` | Recepção **escreve** pagamento, não só lê status | Admin `SELECT` + talvez `UPDATE status`; insert via webhook/RPC |
| `cancellation_reasons` | Já migrado: financeiro ALL, admin SELECT, ativos públicos | Conferir se o push da `20260827000100` chegou em prod |
| `get_receptionist_monthly_ranking` | Só `role = admin` | Combinado; financeiro usa CSV em “Quem indicou” |

### Conferir no SQL Editor (prod), logado como cada role

```sql
-- Como recepção: isto NÃO deveria passar
update public.partners set discount_percentage = 90 where true;

-- Como parceiro: isto NÃO deveria passar
insert into public.partner_validations (
  partner_id, user_id, user_name, service_name, discount_applied
) values ('...', '...', 'Fake', 'x', 999);
```

---

## 4. Problemas de segurança (além de RLS)

**Altos**

1. **Staging = prod** — dado real, teste mistura com cliente.
2. **Recepção = `is_admin()` no Postgres** — a UI “não mostra planos/parceiros”; um APK modificado ou o REST do Supabase mostra. Tratar recepção como operador, não dono do banco.
3. **INSERT de `partner_validations` pelo cliente** — fraude de histórico / “economia”.
4. **Webhooks InfinityPay com `--no-verify-jwt`** — correto para o provedor chamar, **obrigatório** validar assinatura/secret no body. Woovi já tem HMAC; conferir InfinityPay do mesmo jeito. Sem isso qualquer um posta “pago”.
5. **Service role** — nunca no app Flutter. Só Edge Functions (`Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")` em `supabase/functions/`). O dashboard injeta essa env na function; se vazar, bypassa RLS.

**Médios**

6. **QR da carteirinha é UUID estável** — print/encaminhar WhatsApp. Mitigado pela validação no **aparelho do parceiro/recepção** + conferência de documento. Não é OTP de 30s.
7. **`validate_dependent_qr` aceita `is_parceiro()`** — lab pode validar QR de **agendamento de clínica**, se alguém mostrar. MVP de clube usa `validate_loyalty_card`; o RPC antigo ainda está aberto.
8. **Anon key no binário** (`--dart-define` / default em config) — normal no Supabase; a defesa é RLS. Não colocar **service role** nem senha de DB no app.
9. **Google Sign-In sem código de recepção** — não é invasão, é furo de atribuição.
10. **Exclusão de conta não implementada** — LGPD + conta zumbi com QR válido.

**Baixos / higiene**

11. `applicationId` `com.example` e signing debug — loja, não SQL.
12. Handle InfinityPay default no `initDev` — não usar default de prod no binário de loja.
13. Rate limit: login/cadastro/reset = Auth nativo do Supabase. Carteirinha (`validate_loyalty_card` e RPCs irmãs) = 30/min por `auth.uid()`. Confirmação do parceiro = 20/min. Edge Functions autenticadas Woovi (create/cancel/reconcile) = 5–10/min via `try_consume_rate_limit`. Webhooks não entram no teto (HMAC/secret).

---

## 5. Autenticação e autorização — veredito

| Camada | Está correto? |
|---|---|
| Login (email/Google → sessão Supabase) | Sim |
| JWT em `auth.uid()` nas RPCs novas de carteirinha | Sim |
| UI esconde tela por role | Sim, **insuficiente** |
| RLS impede recepção de gerir `partners` / cupom / pagamento | **Não** — `is_admin()` é largo demais |
| Parceiro só honra % (não inventa validação) | **Não** — tem INSERT na tabela |
| Webhooks | Woovi ok; InfinityPay conferir assinatura |
| Segredos no cliente | Anon key ok; service role e DB password não podem ir no APK |

Conclusão: o **modelo** (Auth + RLS + RPC) está certo. A migration `20260827000200_tighten_partner_payment_rls.sql` aperta `partners` / `partner_validations` / `payments` e tira `parceiro` de `validate_dependent_qr`. Recepção deixa de ter `ALL` nessas tabelas.

---

## 6. Como consertar (o que já foi / o que falta)

### Já aplicado no banco (dev + prod)

Migration `20260827000200`: recepção não gerencia `partners`/`payments`; parceiro não inventa `partner_validations`; lab não valida QR de agendamento da clínica.

Migration `20260827000300`: preço de plano, badge e cupom só o **financeiro** grava.

### Service role — não se “tira” do projeto

Não entra no Flutter (já está assim). Consertar é:

1. Nunca copiar **Settings → API → `service_role`** para o app, `--dart-define`, Slack ou git.
2. Se já vazou: Dashboard → **API → Reset service role key** (rotaciona). Edge Functions pegam a nova sozinhas no próximo deploy.
3. Quem usa: só `supabase/functions/*` via `SUPABASE_SERVICE_ROLE_KEY` (injetada no deploy). É o que o webhook usa para marcar pagamento **depois** de conferir no provedor.

A anon key no APK **não se remove** — é pública por desenho. A defesa é a RLS.

### InfinityPay sem JWT

O webhook **não pode** exigir JWT do usuário (o banco da InfinitePay que chama). Consertar:

1. Manter `--no-verify-jwt` (já está).
2. Continuar o `payment_check` na API da InfinitePay (já está — não confia no body sozinho).
3. Definir secret: `supabase secrets set INFINITYPAY_WEBHOOK_SECRET=...` e o mesmo valor no painel da InfinitePay (`x-webhook-secret`). Se a env estiver vazia, o código não quebra o fluxo atual.

### Staging = prod

Isso não é SQL. Criar projeto `vita-clube-dev`, apontar `initStaging()` para ele, **nunca** rodar `supabase_push_prod` “para testar”. Guia: [SETUP_DEV_PROD.md](./SETUP_DEV_PROD.md).

### O que ainda é produto, não RLS

- Exclusão de conta (LGPD) no app
- Código da recepção na home dela
- QR da carteirinha é UUID (print) — operação: validar no aparelho do caixa + documento

---

## 7. Ordem sugerida

1. `./scripts/supabase_push_prod.sh` (quando `partners` ainda não existe, essa é a causa).
2. Migration nova: recepção não gerencia `partners`; parceiro não INSERT em `partner_validations`.
3. Testar com JWT de cada role no SQL Editor / Postgrest.
4. Só então E2E com dado real ([E2E_TESTES.md](./E2E_TESTES.md)).
