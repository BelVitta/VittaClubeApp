# Notificações

Envio de avisos push/in-app para usuários.

## O que faz
Criar notificação (título, corpo, destino: todos / plano X / usuário específico), agendar envio, ver histórico.

## Fluxo
1. Admin redige notificação → escolhe público-alvo.
2. Envio imediato ou agendado.
3. Push via FCM + registro na tabela `notifications`.

## Permissão Admin (recepcionista)
- ✅ Enviar notificações **operacionais** (lembrete consulta, aviso de fechamento).
- ⚠️ Limite diário (ex: 10/dia) para evitar spam.

## Permissão Super Admin
- ✅ Tudo + campanhas em massa + notificação de marketing.

## Riscos (recepcionista) — ALTO
- Spam em massa → má reputação FCM + perda de usuários.
- Mensagem inadequada/ofensiva enviada para toda base.
- Phishing interno (fingir ser comunicado oficial).
- Mitigação:
  - Rate limit por admin (ex: 10 envios/dia, 1 broadcast/dia).
  - Templates pré-aprovados para broadcast.
  - Broadcast para "todos" exige **financeiro**.
  - `audit_log` com conteúdo e autor.

## RLS Supabase
- `INSERT` com `target=all`: apenas financeiro.
- `INSERT` com `target=user_id`: admin + financeiro.
