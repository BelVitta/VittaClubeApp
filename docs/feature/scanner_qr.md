# Scanner QR

Leitura do QR da carteirinha digital do usuário para validar atendimento.

## O que faz
Abre câmera → lê QR → valida assinatura + plano ativo → mostra dados do usuário → registra check-in.

## Fluxo
1. Usuário chega à recepção, mostra QR da carteirinha.
2. Admin escaneia.
3. Sistema verifica: QR válido? Plano ativo? Consulta agendada hoje?
4. Exibe: nome, plano, consulta do dia.
5. Opção "Confirmar presença" marca consulta como `in_progress`.

## Permissão Admin (recepcionista)
- ✅ Escanear e confirmar presença.
- ✅ Ve apenas dados estritamente necessários (nome, plano, consulta).

## Permissão Super Admin
- ✅ Tudo + relatório de check-ins.

## Riscos (recepcionista) — MÉDIO
- QR roubado/screenshot: ataque de replay.
- Vazamento de dados pessoais na tela.
- Mitigação:
  - QR com **payload assinado** (JWT curto, ex: 5min) ou challenge dinâmico.
  - Tela do scanner mostra **mínimo viável** (nome + foto + plano).
  - Se scanner for ofensor: rate limit (máx X scans/min).
  - `check_in_log` obrigatório.

## RLS Supabase
- Validação feita via RPC `validate_qr(token)` que retorna dados limitados conforme role.
- `INSERT check_in`: admin + financeiro.
