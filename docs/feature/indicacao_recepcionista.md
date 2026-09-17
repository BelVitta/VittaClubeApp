# Indicação das recepcionistas e ranking

Como o app funciona **hoje**. `role = admin` **é** a recepcionista (não existe papel `recepcionista`). Tudo na operação do clube continua presencial: ela fala o código no balcão; o indicado digita no cadastro.

Isso **não** é o “Indique e ganhe” do membro (`lib/features/referral`). São dois funis.

Schema e regras: `supabase/migrations/20260709000100_receptionist_referrals.sql` (ranking depois restrito em `20260710000500_restrict_receptionist_ranking.sql`).

---

## 1. Papéis

| Quem | Login | Faz |
|---|---|---|
| Recepcionista | `admin` | Ganha `receptionist_code` automático; vê ranking do mês; lista “Quem indicou” |
| Indicado | `user` | No cadastro por e-mail/senha, campo opcional “Código de quem te indicou” |
| Financeiro | `financeiro` | Vê a lista, exporta CSV, **corrige** atribuição (RPC auditada). **Não** acessa o ranking (RPC recusa) |

O código da recepcionista é imutável para o próprio usuário (`receptionist_code imutável` em RLS hardening).

---

## 2. Fluxo presencial (o que o produto assume)

```
Balcão Vitta
  recepcionista fala/mostra o código (ex. MAR0421)
        ↓
Indicada abre o app → Criar conta
  campo opcional: "Código de quem te indicou"
        ↓
Signup grava receptionist_code no metadata do Auth
        ↓
Trigger handle_new_user:
  se o código existir e for de um profile role=admin
    → linha receptionist_referrals status = pending
  se o código for inválido ou vazio
    → cadastro segue; ninguém leva a indicação
        ↓
Indicada assina (primeira vez na vida que a subscription fica active)
        ↓
Trigger handle_subscription_activated:
  pending → converted
  grava preço do plano naquele instante + month_reference (YYYY-MM)
  profiles.first_subscription_converted_at = agora
        ↓
Reativação / renovação NÃO gera segundo crédito
```

Validação humana: a recepcionista **não** confirma a indicação no app. O vínculo é o código digitado no cadastro. Se errou o código, o financeiro corrige depois em “Quem indicou”.

Não há upload de documento nem fila de “aprovar indicação”. Combina com o resto do clube: o que precisa de olho no balcão (dependente, QR) é outro fluxo.

---

## 3. O que cada tela faz

### Cadastro do membro (`RegisterPage`)

Campo **opcional** `Código de quem te indicou`. Vai em `auth.signUp(data: { receptionist_code })`. Só o registro e-mail/senha. **Login Google não envia esse código** — indicado que entra só com Google não atribui recepcionista.

Código errado não barra o signup (`ON CONFLICT` / `WARNING` no trigger).

### Código da recepcionista

Gerado no trigger `assign_receptionist_code` quando `role` vira `admin`: 3 letras do nome + 4 dígitos (`MAR0421`). Admins antigos foram backfillados.

**Onde aparece no app:** no topo do painel da recepcionista (`AdminDashboardPage`) — código grande + copiar. O financeiro também vê/copia no formulário do usuário admin.

### Ranking (`ReceptionistRankingPage`) — só `admin`

Card “Seu desempenho”: posição, indicações, conversões, total gerado no mês.  
Lista “Ranking completo” de **todas** as recepcionistas (todos os `role = admin`).  
Navegação de mês (setas).

RPC `get_receptionist_monthly_ranking(YYYY-MM)`:

- **Indicações** do mês = linhas cuja `created_at` cai naquele mês (cadastrou com o código)
- **Conversões** do mês = linhas com `month_reference` = aquele mês (assinou de primeira naquele mês)
- **Total gerado** = soma de `plan_price_at_conversion` das conversões do mês
- Ordem: conversões desc, total desc, nome asc

Quem cadastrou em março e só pagou em abril: indicação em março, conversão em abril.

Acesso: a migration `20260710000500` deixou a RPC **só para `role = admin`**. Financeiro chama e toma exception. O card “Ranking Indicações” no dashboard também só renderiza se `role == 'admin'`.

### Quem indicou (`AdminReferralsListPage`) — admin e financeiro

Lista pending/converted, busca, filtro de mês, exportar CSV.  
Financeiro abre sheet **Corrigir atribuição** → RPC `correct_receptionist_referral` (não pode atribuir a si mesmo; grava `audit_log`).

Não há policy de UPDATE na tabela para `authenticated`. Depois de convertida, só essa RPC mexe em `receptionist_id`.

---

## 4. Ranking — o que ele mede (e o que não)

Mede **produção comercial da recepção**, não o ranking de membros da Home (badges / “Indique e ganhe”).

| Número | Significado |
|---|---|
| Indicações | Quantas pessoas **cadastraram** com o código dela naquele mês |
| Conversões | Quantas **pagaram a primeira assinatura** naquele mês |
| Total gerado | Soma do **preço do plano no momento da conversão** (não recorrência futura) |

Não entra: renovação, inadimplente que volta, indicação de membro-para-membro, parceiro.

O ranking lista inclusive recepcionista com zero no mês (LEFT JOIN em todos os admins), para a equipe ver quem não indicou.

---

## 5. Encaixe com o clube presencial

O funil certo no balcão:

1. Pessoa chega sem app.
2. Recepcionista explica o clube e **passa o código** (como o QR da carteirinha: ela mostra, o outro digita).
3. Cadastro no celular da pessoa **na hora**, com o código.
4. Assinatura (Pix/cartão) — pode ser no mesmo atendimento.
5. Ranking só conta conversão quando o pagamento marca `subscriptions.status = 'active'` **a primeira vez**.

O que **não** está alinhado com “tudo validado pessoalmente”:

- Não existe passo “recepção confirma que essa pessoa veio comigo” depois do cadastro. Quem digitou o código leva a indicação, mesmo de casa.
- Google Sign-In pula o campo do código.
- A própria recepcionista **não vê o código na home** — difícil falar no balcão se ninguém copiou antes.
- Código inválido some em silêncio (cadastro ok, ranking não conta).

Se a operação quiser o mesmo rigor do dependente (`pending` até o balcão), faltaria um estado “indicação à espera de confirmação da recepção”. Hoje isso **não existe** de propósito: o código no signup já é o carimbo.

---

## 6. Dois funis de “indicação”

| | Recepcionista | Membro (Indique e ganhe) |
|---|---|---|
| Quem indica | `admin` no balcão | `user` no app |
| Código | `profiles.receptionist_code` | feature `referral` |
| Conversão | Primeira assinatura `active` | regras próprias de indicação/badge |
| Ranking | `ReceptionistRankingPage` | ranking de membros / badges |

Não misturar na ficha da loja nem no texto da recepção.

---

## 7. Lacunas se o fluxo presencial for o produto

- Mostrar **código grande + copiar** no dashboard da recepcionista (e no card “Seu desempenho”).
- Campo de código no fluxo Google, ou bloquear “indicação” para quem só entra com Google até completar o cadastro.
- Feedback no signup se o código não existir (“código não encontrado; você pode continuar”).
- Financeiro: se precisar ver o ranking, a RPC atual recusa — ou reabre leitura para `financeiro` ou um relatório só no CSV.

Nada disso é Play Store; é operação de balcão.
