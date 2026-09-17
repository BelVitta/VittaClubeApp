# Vitta Clube V1 — Análise de jornadas, telas e o que ficou de fora

Documento de trabalho para o **documento de entrega**. Baseado no código atual (setembro/2026), não na spec antiga.

- Produto: clube de benefícios de saúde (consultas com desconto, carteirinha QR, dependentes, parceiros, indicações).
- App: Flutter (Android / iOS), Clean Architecture + BLoC.
- Backend: Supabase (Postgres, Auth, RLS, Storage, Edge Functions).
- Firebase: Google Sign-In + FCM (push). **Não** usa Firestore.
- Manutenção combinada: **4 meses gratuitos** após a entrega (escopo operacional, não features novas).

Status: **MVP operável**. Cobrança de cartão via InfinityPay. PIX no checkout ainda usa o gateway mock / bloqueado em prod. PIX Automático Woovi existe no backend e nas telas de explicação, mas o botão PIX da `PaymentPage` **não** abre esse fluxo.

---

## 1. Papéis

| Papel | `profiles.role` | Quem é | App entra em |
|-------|-----------------|--------|----------------|
| Membro | `user` | Paciente que paga o plano | Home (abas) |
| Recepcionista | `admin` | Balcão da clínica | Painel Administração |
| Financeiro | `financeiro` | Dono / gestor | Painel Financeiro (+ atalho para o operacional) |
| Parceiro | `parceiro` | Farmácia / lab / clínica conveniada | Painel Parceiro |

Hierarquia de permissão no banco: `is_financeiro()` ⊂ gestão estratégica; `is_admin()` hoje inclui **admin e financeiro** (migration `20260608000100`). Recepcionista não cria outros admins nem muda `role`.

Dependente **não tem login**. É cadastro do titular; usa o QR gerado pelo titular no agendamento.

---

## 2. Stack e arquivos entregues

| Camada | O quê |
|--------|--------|
| App | `lib/` Flutter, entry points `main_dev.dart` / `main_staging.dart` / `main_prod.dart` |
| Banco | `supabase/migrations/` (fonte da verdade). `schema.sql` é referência, **não** aplicar em prod |
| Funções | Woovi (create/webhook/reconcile/cancel), InfinityPay (checkout webhook + return), `send-push-campaign`, `health-check` |
| Auth | Supabase Auth (e-mail/senha, recovery). Google via Firebase ID token → `signInWithIdToken` |
| Pagamento cartão | InfinityPay checkout (redirect + webhook) |
| Pagamento PIX automático | Edge Functions Woovi prontas; **checkout do app ainda não conecta** |
| Push | FCM HTTP v1, secret `FCM_SERVICE_ACCOUNT_JSON` nos projetos **dev e prod** |
| Legal | `assets/legal/termos-de-uso.md`, `politica-de-privacidade.md` |
| Deploy | `./scripts/supabase_push_dev.sh` e `supabase_push_prod.sh` |

Contas / licenças do cliente: Apple Developer, Google Play, Supabase (dev + prod), Firebase, InfinityPay, Woovi (sandbox + prod), opcionalmente Mercado Pago (não integrado nesta V1).

---

## 3. Mapa de telas (V1)

### 3.1 Comuns (antes do papel)

| História | Telas | Situação |
|----------|-------|----------|
| Abrir o app | `SplashPage` | Sessão 24h local + JWT Supabase |
| Primeira vez | `OnboardingPage` (3 telas) | Só UI |
| Entrar | `LoginPage` | E-mail/senha + Google |
| Cadastrar | `RegisterPage` | Nome, CPF, telefone, e-mail, senha; código de recepcionista opcional |
| Esqueci senha | `ForgotPasswordPage` → e-mail → `ResetPasswordPage` (deep link `vittaclube://auth/reset-password`) | Integrado ao Supabase + Resend |
| Completar cadastro Google | `PersonalDataPage` (modo obrigatório) | CPF/telefone |

`VerifyCodePage` existe; o fluxo de senha atual usa **link**, não OTP nessa tela.

### 3.2 Membro — abas

Home · Profissionais · Carteirinha · Perfil.

| História | Telas | Regras | Lacuna |
|----------|-------|--------|--------|
| Ver status do plano | `HomePage` + `PlanBanner` / `NoPlanCard` | Sem assinatura: CTA de planos. Com plano: patente/badge | — |
| Ver benefícios | `BenefitsPage` | Conteúdo do plano | — |
| Pagar / renovar | `PlansPage` → `PaymentPage` → InfinityPay (cartão) | Ativa `subscriptions` no webhook/retorno | PIX da tela usa `PaymentGateway` mock; em prod o mock não cobra de verdade |
| Histórico de pagamentos | `PaymentsPage` | Lista `payments` | — |
| Cancelar plano | `CancellationPage` + `CancellationReasonPage` | Se Pix Automático, chama `cancel-woovi-subscription` | — |
| Escolher profissional | `ProfessionalsPage` | Filtro especialidade; disponibilidade / nota | Sem agenda in-app |
| Agendar consulta | `ConsultationSchedulePage` | Escolhe titular ou dependente, gera QR (sem debitar cota), abre WhatsApp | Número é o da **clínica** (`clinic_settings`), não o do profissional. Cota mensal por patente **não** é checada nessa tela. |
| Usar carteirinha | `CardPage` + `QrCodeSheet` | QR só se `canUseQr` (assinatura com acesso) | Código de 8 dígitos (`member_code`) para digitação no balcão |
| Cadastrar dependente | `DependentsPage` | Quota, ciclo, aprovação admin | Dependente não loga |
| Usar parceiro | `PartnersListPage` → `PartnerDetailPage` | Mostra % do acordo; copy: mostrar **carteirinha no caixa** do estabelecimento | `PartnerCheckinPage` (OTP) existe e **não é navegada**. Quem valida é o app do parceiro. |
| Indicar amigos | `ReferralPage` / `ReferralHistoryPage` | Limite mensal, elegibilidade | **Telas prontas, sem menu no membro.** Cadastro só aceita código da recepcionista, não o do amigo. |
| Caixa de avisos | `NotificationsPage` + sino | Campanhas in-app + push FCM | Agendar envio e push automático (consulta/badge) fora da V1 |
| Preferências de push | `NotificationSettingsPage` | `novidades` bloqueia campanha de divulgação | — |
| Dados / privacidade / senha | `PersonalDataPage`, `PrivacyDataPage`, `SecurityPage` | CPF/telefone via RPC criptografada | LGPD: exportação completa e exclusão de conta ainda parciais |
| Seja parceiro | `SejaParceiroPage` → `ParceiroRegisterPage` | Candidatura; financeiro aprova | — |

### 3.3 Recepcionista (`admin`)

Entrada: `AdminDashboardPage`. Código de indicação da recepcionista no header.

**Cadastros:** profissionais, especialidades, usuários (sem mudar `role`), dependentes (aprovar/rejeitar).

**Operações:** pagamentos (leitura), consultas, notificações (templates + campanha para **1** membro), sorteios (CRUD; execução pode ser restrita), cupons (aplicar vs criar — financeiro dono da criação), scanner QR, ranking de indicações, “quem indicou”.

**Como comprova o paciente no balcão (V1):**

1. Paciente abre **Carteirinha** e mostra o QR (titular) **ou** o QR do agendamento (titular/dependente).
2. Recepcionista abre **Scanner QR** (`AdminQrScannerPage`).
3. RPC `validate_member_qr` ou `validate_dependent_qr`: assinatura HMAC, plano com acesso, cota, desconto da patente.
4. Recepcionista informa valor da consulta; sistema grava economia e consome cota.
5. Sem câmera: paciente dita o **código de 8 dígitos** (`member_code`) — fluxo de digitação no scanner.

Agendamento WhatsApp: o app **não** marca horário. A consulta “de verdade” no calendário da clínica é o WhatsApp. O app gera o QR **sem debitar cota**; o débito é no scan.

Broadcast de notificação para todos: **só financeiro**. Recepcionista: 10 envios/dia para um usuário.

**Armadilhas de UI vs banco (não copiar no contrato como “a recepção faz”):**
- Card **Cupons** no dashboard admin: lista sim; insert/update falha para `admin`.
- **Candidaturas parceiro** no admin: aprovar tenta promover `role=parceiro` e o trigger bloqueia quem não é financeiro.
- Lista de pagamentos da recepção **mostra valor em R$** (a spec antiga pedia só status).
- `is_admin()` no Postgres inclui financeiro — a separação fina é `is_financeiro()` + UI.

### 3.4 Financeiro

`FinanceiroDashboardPage`: métricas (assinantes, receita do mês, etc.), planos, badges, usuários, pagamentos, motivos de cancelamento, parceiros (aprovar candidatura), atalho para o painel admin.

Não há Mercado Pago nesta V1. Cartão = InfinityPay. PIX automático = Woovi (backend pronto, checkout do membro incompleto).

### 3.5 Parceiro

- Candidato membro: `SejaParceiroPage` / registro.
- Aprovado (`role=parceiro`): `ParceiroDashboardPage` — serviços, histórico de validações, tela de validar token do membro (`ParceiroValidatePage` / check-in).
- Membro no estabelecimento: gera código na `PartnerCheckinPage`; parceiro confirma e registra o desconto.

---

## 4. Histórias de uso (cenários ponta a ponta)

### HU-01 — Cliente novo compra o clube
1. Onboarding → cadastro (CPF único) → Home sem plano.
2. Planos → escolhe mensal/semestral/anual → cartão InfinityPay.
3. Webhook/retorno marca pagamento e ativa assinatura.
4. Home mostra patente inicial; QR da carteirinha libera.

**Fora / risco:** PIX da mesma tela não é InfinityPay nem Woovi em produção.

### HU-02 — Consulta com desconto (titular)
1. Profissionais → especialidade → “agendar”.
2. Escolhe titular → gera QR de agendamento → WhatsApp.
3. No dia, na recepção: scanner valida QR, aplica % da patente, registra consulta.

### HU-03 — Dependente
1. Titular cadastra dependente (pendente).
2. Recepcionista aprova na lista de dependentes.
3. Titular agenda escolhendo o dependente; QR leva `dependent_id`.
4. Scan `validate_dependent_qr` consome cota do **titular**.

### HU-04 — Parceiro (farmácia)
1. Membro lista parceiros → vê % e serviços.
2. No caixa, mostra a **carteirinha** (QR ou 8 dígitos).
3. App do parceiro (`ParceiroValidatePage`) lê e confirma; RPC `confirm_partner_validation`.
4. % é o **acordo do financeiro**, não a patente da clínica. Os dois **não somam**.

### HU-05 — Indicação
1. Funil vivo no cadastro: campo **código da recepcionista** (não o do amigo).
2. Ranking: `ReceptionistRankingPage` (só `admin`; financeiro não chama essa RPC).
3. Telas “Indique e ganhe” do membro existem, **sem entrada na navegação** — tratar como fora da porta da frente até ligar o menu.

### HU-06 — Inadimplência
Política: `SubscriptionAccessPolicy` — ativo + `allowed` usa QR; `paymentPending` pode ter aviso; cancelado só até `currentPeriodEnd`. Home/carteirinha bloqueiam benefício se `canAccessBenefits` for falso.

### HU-07 — Divulgação (especialista da semana)
Financeiro: Notificações → campanha → todos. Inbox + FCM. Toque abre profissionais/agendamento.

---

## 5. Segurança (para o capítulo do contrato)

- RLS em todas as tabelas sensíveis; RPCs `SECURITY DEFINER` com `is_admin` / `is_financeiro` / `auth.uid()`.
- CPF e telefone criptografados (Vault); busca por hash; RPC `update_user_sensitive_profile`.
- QR assinado HMAC-SHA256, curto prazo, anti-replay nas RPCs de validação.
- Rate limit (`try_consume_rate_limit`) em QR, campanhas, cadastros sensíveis.
- Sessão app 24h + sign-out Google no logout.
- Push: token por aparelho; secret FCM só no servidor.
- Backup / retenção: responsabilidade do plano Supabase do cliente.
- LGPD: termos e política no app; exportação/exclusão total ainda não são um botão único “baixar todos os dados”.

---

## 6. O que está na V1 vs o que ficou de fora

**Na V1 (entregar e operar):**
- 4 papéis e painéis.
- Cadastro, Google, recuperação de senha.
- Planos + cartão InfinityPay + histórico + cancelamento.
- Carteirinha, QR titular e dependente, cota, desconto por patente.
- Profissionais + WhatsApp.
- Dependentes com aprovação.
- Parceiros (candidatura, lista, check-in).
- Indicações + ranking recepcionista.
- Campanhas in-app + FCM (sem agendar).
- Painel admin/financeiro básico.

**Fora da V1 (manutenção 4 meses = correção, não construção):**
- PIX Automático Woovi **ligado no botão do checkout** (functions e telas `BillingProfile` / explicação existem, o botão PIX da `PaymentPage` não navega até elas; em prod o `PaymentGateway` recusa).
- Mercado Pago (só documento; sem function).
- Agenda com grade de horários (hoje é WhatsApp da clínica).
- Sorteio automático + tela do membro (CRUD admin sem mecânica).
- Cupom na jornada do membro. No painel da recepção o card **Cupons** aparece, mas **gravar é só financeiro** (RLS).
- Indicação entre amigos no app do membro (código no cadastro + menu).
- Upgrade automático de patente (`CheckBadgeUpgrade` não dispara na Home). Novas assinaturas entram sempre **bronze**.
- Aprovação de parceiro pela recepção (o botão existe; o trigger só deixa o **financeiro** mudar `role`).
- Push agendado e transacional.
- APNs iOS produção + teste de token no aparelho.
- Relatórios financeiros ricos, MFA, exclusão LGPD one-click.

---

## 7. Manutenção gratuita (4 meses) — o que cabe

Incluir: bugs de produção, RLS/auth, InfinityPay/Woovi já ligados, ajuste de copy, crash, build Play/App Store da versão entregue.

Não incluir: Mercado Pago do zero, agenda completa, novos papéis, redesenho, novos módulos.

---

## 8. Como usar este arquivo no Word de entrega

O Codex gerou o modelo em `output/documents/modelo-entrega-aplicativo-vittaclube.docx` (ainda com placeholders `[NOME DO PROJETO]` etc.).

Preencher com:
- Nome: **Vitta Clube**
- Seção funcionamento: capítulos 3–4 deste arquivo
- Segurança: capítulo 5
- Infra: capítulo 2
- Fora de escopo: capítulo 6
- SLA: capítulo 7

---

*Gerado a partir do código em `lib/` e `supabase/`. Specs em `docs/PAPEIS_E_PERMISSOES.md` e `docs/ANALISE_FUNCIONALIDADES.md` estão parcialmente desatualizadas (ex.: parceiros e notificações já existem).*
