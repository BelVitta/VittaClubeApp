#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/supabase.env"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

: "${SUPABASE_DEV_REF:?Set SUPABASE_DEV_REF in supabase.env}"

export SUPABASE_DB_PASSWORD="${SUPABASE_DEV_DB_PASSWORD:-${SUPABASE_DB_PASSWORD:-}}"

cd "${ROOT_DIR}"

echo "Linking Supabase dev project: ${SUPABASE_DEV_REF}"
supabase link --project-ref "${SUPABASE_DEV_REF}"

if [[ -n "${INFINITYPAY_HANDLE:-}" ]]; then
  echo "Setting InfinityPay Edge Function secrets"
  supabase secrets set "INFINITYPAY_HANDLE=${INFINITYPAY_HANDLE}"
fi

if [[ -n "${INFINITYPAY_CHECKOUT_API_URL:-}" ]]; then
  supabase secrets set "INFINITYPAY_CHECKOUT_API_URL=${INFINITYPAY_CHECKOUT_API_URL}"
fi

if [[ -z "${FCM_SERVICE_ACCOUNT_JSON:-}" && -n "${FCM_SERVICE_ACCOUNT_JSON_FILE:-}" && -f "${FCM_SERVICE_ACCOUNT_JSON_FILE}" ]]; then
  FCM_SERVICE_ACCOUNT_JSON="$(cat "${FCM_SERVICE_ACCOUNT_JSON_FILE}")"
fi
if [[ -n "${FCM_SERVICE_ACCOUNT_JSON:-}" ]]; then
  echo "Setting FCM service account secret"
  supabase secrets set "FCM_SERVICE_ACCOUNT_JSON=${FCM_SERVICE_ACCOUNT_JSON}"
fi

echo "Migration status before push"
supabase migration list

# --include-all: aplica placeholders / versões fora de ordem quando o
# histórico remoto e local já estão reconciliados.
# --yes: não trava em prompt interativo em CI/agent.
echo "Pushing migrations to dev"
if ! supabase db push --include-all --yes; then
  cat <<'EOF'

ERROR: supabase db push failed.

Causa comum: versão no remoto que não existe em supabase/migrations/
(ex.: placeholder curto "20260601").

Diagnóstico:
  supabase migration list

Se o remoto listar uma versão sem coluna Local:
  supabase migration repair --status reverted <VERSION>

Depois rode de novo:
  ./scripts/supabase_push_dev.sh
EOF
  exit 1
fi

echo "Deploying Edge Functions to dev"
supabase functions deploy health-check
supabase functions deploy create-woovi-subscription
supabase functions deploy woovi-webhook
supabase functions deploy reconcile-woovi-subscription
supabase functions deploy cancel-woovi-subscription
supabase functions deploy infinitypay-webhook --no-verify-jwt
supabase functions deploy infinitypay-return --no-verify-jwt
supabase functions deploy send-push-campaign

echo "Migration status after push"
supabase migration list

echo "Dev Supabase deploy finished."
