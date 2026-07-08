# Implementation Plan: Pagamentos e Assinatura Pix Automático

**Branch**: `002-pix-auto-subscription` | **Date**: 2026-06-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-pix-auto-subscription/spec.md`

## Summary

Implementar assinatura mensal recorrente obrigatória do VittaClube via Pix Automático Woovi, com valor fixo de R$34,90, jornada `PAYMENT_ON_APPROVAL`, retry policy de até 3 tentativas em 7 dias, webhook idempotente e controle de acesso centralizado no status da assinatura persistido no Supabase/Postgres. O app Flutter deve apenas iniciar a jornada, abrir o link de autorização, refletir o status real da assinatura e bloquear QR/benefícios/dependentes quando a assinatura estiver inadimplente ou encerrada. A lógica sensível fica em Supabase Edge Functions backend-only.

## Technical Context

**Language/Version**: Flutter/Dart conforme projeto atual; Supabase Edge Functions em Deno/TypeScript; SQL/Postgres para schema e políticas.

**Primary Dependencies**: Supabase, Supabase Edge Functions, Postgres/RLS, Woovi API Pix Automático, Flutter BLoC/GetIt/dartz já existentes, `url_launcher` para abrir link de autorização.

**Storage**: Supabase Postgres. Persistência exigida para `subscriptions`, `subscription_charges`, `subscription_charge_attempts`, `woovi_webhook_events`, `subscription_access_events`/histórico operacional e status de pagamento do titular.

**Testing**: `flutter test` para domínio/UI mobile; testes Deno das Edge Functions; testes SQL/RLS com Supabase local ou staging; testes de contrato dos payloads Woovi; testes de sandbox ponta a ponta.

**Target Platform**: Aplicativo mobile Flutter para usuário/operador; Supabase Edge Functions como backend serverless; Supabase Postgres como fonte de verdade.

**Project Type**: Mobile app + backend serverless + banco Postgres.

**Performance Goals**: Tela de status deve refletir estado local/remoto em até 2 segundos em rede normal; webhook deve responder 2xx após deduplicação/processamento básico em até 1 segundo para evitar reenvios desnecessários; ações sensíveis devem ter feedback imediato.

**Constraints**: Backend-only para integração Woovi; nenhum `WOOVI_APP_ID` ou `WOOVI_WEBHOOK_SECRET` no app; webhooks validados por HMAC antes do processamento; eventos idempotentes por ID; status da assinatura no Postgres controla acesso; QR de benefício bloqueado quando assinatura estiver `blocked`, `cancelled`, `rejected` ou sem período pago vigente.

**Scale/Scope**: Uma assinatura ativa por titular; valor fixo R$34,90; sem plano gratuito; sem trial; sem cartão; sem cobrança adicional por dependente; suporte a sandbox e produção por variáveis de ambiente.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Business outcome**: PASS. A feature protege MRR, reduz churn involuntário e bloqueia uso sem pagamento.
- **Trust and conversion**: PASS. A jornada exige tela explicativa antes do banco, preço claro, recorrência explícita e CTA de restauração.
- **Mobile-first UX/UI**: PASS. Estados mobile de paywall, aguardando banco, ativa, pendente, bloqueada, recusada e cancelada estão planejados.
- **Accessibility**: PASS. Modais, CTAs, mensagens financeiras e status terão labels, contraste e leitura por tecnologias assistivas.
- **Clean architecture by feature**: PASS. Flutter evolui `features/subscription`; integração externa fica em Edge Functions; Supabase fica atrás de datasources/repositórios.
- **Automated tests**: PASS. Plano inclui testes unitários, widget, contratos, Edge Functions, RLS e sandbox.
- **Performance and SEO local**: PASS. Performance explícita para status/webhook. SEO local não se aplica à jornada autenticada; se houver paywall público, seguir spec.
- **Simplicity**: PASS. Reaproveita feature `subscription`, `PaymentGateway` como referência de fronteira e Supabase existente; complexidade adicional se justifica por segurança financeira, idempotência e recorrência assíncrona.

## Project Structure

### Documentation (this feature)

```text
specs/002-pix-auto-subscription/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── edge-functions.md
│   ├── woovi-webhook-events.md
│   └── mobile-ui-states.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── payment/
│   │   ├── payment_gateway.dart              # manter para gateways legados/futuros; Pix Automático usa backend-only
│   │   └── mock_payment_gateway.dart
│   └── services/
├── features/
│   ├── subscription/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   ├── plans/
│   │   └── presentation/
│   ├── card/
│   │   └── presentation/                      # bloquear QR por status de assinatura
│   └── dependents/
│       └── domain/                            # dependentes herdam bloqueio do titular
supabase/
├── functions/
│   ├── create-woovi-subscription/
│   │   └── index.ts
│   ├── woovi-webhook/
│   │   └── index.ts
│   └── reconcile-woovi-subscription/
│       └── index.ts
└── migrations/
    └── YYYYMMDD_pix_automatic_subscription.sql
test/
├── features/
│   └── subscription/
└── core/
supabase/tests/
└── subscription_rls_and_webhooks.sql
```

**Structure Decision**: Evoluir a feature Flutter existente `lib/features/subscription` em vez de criar uma segunda feature de pagamento. Toda integração Woovi fica em `supabase/functions` para manter segredo, HMAC, idempotência e reconciliação fora do app. O banco preserva `public.subscriptions` como fonte de verdade, ampliando o schema para Pix Automático e criando tabelas específicas para cobranças, tentativas e eventos.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Edge Functions backend-only | Integração financeira exige segredo, HMAC e reconciliação fora do app | Chamar Woovi direto do Flutter exporia credenciais e permitiria manipulação indevida |
| Tabela de eventos para deduplicação | Webhooks são assíncronos e podem ser reenviados | Processar sem deduplicação geraria risco de dupla liberação/notificação |
| Tabelas separadas de cobrança/tentativa | Retentativas e janela de recuperação precisam ser auditáveis | Armazenar tudo em `subscriptions` perderia histórico e dificultaria suporte |

## Phase 0: Research

Ver [research.md](./research.md).

## Phase 1: Design & Contracts

Ver [data-model.md](./data-model.md), [contracts/edge-functions.md](./contracts/edge-functions.md), [contracts/woovi-webhook-events.md](./contracts/woovi-webhook-events.md), [contracts/mobile-ui-states.md](./contracts/mobile-ui-states.md) e [quickstart.md](./quickstart.md).

## Post-Design Constitution Check

- **Business outcome**: PASS. O design mede ativação, cobrança, recuperação e bloqueio.
- **Trust and conversion**: PASS. Contratos de UI exigem preço/recorrência/cancelamento antes da autorização.
- **Mobile-first UX/UI**: PASS. Estados mobile e modal de restauração estão contratados.
- **Accessibility**: PASS. Estados e mensagens devem ter labels, foco e conteúdo textual.
- **Clean architecture by feature**: PASS. App, domínio, datasources, Edge Functions e Postgres têm fronteiras claras.
- **Automated tests**: PASS. Quickstart e contratos definem testes obrigatórios.
- **Performance and SEO local**: PASS. Performance de status/webhook definida; SEO N/A para fluxo autenticado.
- **Simplicity**: PASS. Aproveita a base atual e adiciona apenas superfícies necessárias para recorrência segura.
