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

if [[ -n "${MERCADOPAGO_ACCESS_TOKEN:-}" && -n "${MERCADOPAGO_WEBHOOK_SECRET:-}" && -n "${MERCADOPAGO_RETURN_URL:-}" ]]; then
  echo "Setting Mercado Pago Edge Function secrets"
  supabase secrets set \
    "MERCADOPAGO_ACCESS_TOKEN=${MERCADOPAGO_ACCESS_TOKEN}" \
    "MERCADOPAGO_WEBHOOK_SECRET=${MERCADOPAGO_WEBHOOK_SECRET}" \
    "MERCADOPAGO_RETURN_URL=${MERCADOPAGO_RETURN_URL}"
  if [[ -n "${MERCADOPAGO_CRON_SECRET:-}" ]]; then
    supabase secrets set "MERCADOPAGO_CRON_SECRET=${MERCADOPAGO_CRON_SECRET}"
  fi
  if [[ -n "${MERCADOPAGO_API_URL:-}" ]]; then
    supabase secrets set "MERCADOPAGO_API_URL=${MERCADOPAGO_API_URL}"
  fi
fi

woovi_dev_app_id="${WOOVI_DEV_APP_ID:-${WOOVI_APP_ID:-}}"
woovi_dev_webhook_secret="${WOOVI_DEV_WEBHOOK_SECRET:-${WOOVI_WEBHOOK_SECRET:-}}"
if [[ -n "${woovi_dev_app_id}" && -n "${woovi_dev_webhook_secret}" ]]; then
  echo "Setting Woovi Pix Automático secrets"
  supabase secrets set \
    "WOOVI_ENVIRONMENT=${WOOVI_DEV_ENVIRONMENT:-${WOOVI_ENVIRONMENT:-sandbox}}" \
    "WOOVI_BASE_URL=${WOOVI_DEV_BASE_URL:-${WOOVI_BASE_URL:-https://api.woovi-sandbox.com}}" \
    "WOOVI_APP_ID=${woovi_dev_app_id}" \
    "WOOVI_WEBHOOK_SECRET=${woovi_dev_webhook_secret}" \
    "VITTACLUBE_SUBSCRIPTION_VALUE_CENTS=${VITTACLUBE_SUBSCRIPTION_VALUE_CENTS:-3490}" \
    "VITTACLUBE_SUBSCRIPTION_INTERVAL=${VITTACLUBE_SUBSCRIPTION_INTERVAL:-MONTHLY}" \
    "VITTACLUBE_SUBSCRIPTION_JOURNEY=${VITTACLUBE_SUBSCRIPTION_JOURNEY:-PAYMENT_ON_APPROVAL}" \
    "VITTACLUBE_RETRY_POLICY=${VITTACLUBE_RETRY_POLICY:-THREE_RETRIES_7_DAYS}"
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
supabase functions deploy create-mercadopago-plan
supabase functions deploy create-mercadopago-subscription
supabase functions deploy cancel-mercadopago-subscription
supabase functions deploy reconcile-mercadopago-subscription
supabase functions deploy update-mercadopago-plan-price
supabase functions deploy cancel-local-subscription
supabase functions deploy mercadopago-webhook --no-verify-jwt
supabase functions deploy mercadopago-return --no-verify-jwt
supabase functions deploy reconcile-mercadopago --no-verify-jwt
supabase functions deploy infinitypay-webhook --no-verify-jwt
supabase functions deploy infinitypay-return --no-verify-jwt
supabase functions deploy send-push-campaign

echo "Migration status after push"
supabase migration list

echo "Dev Supabase deploy finished."
