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

: "${SUPABASE_PROD_REF:?Set SUPABASE_PROD_REF in supabase.env}"

export SUPABASE_DB_PASSWORD="${SUPABASE_PROD_DB_PASSWORD:-${SUPABASE_DB_PASSWORD:-}}"

cd "${ROOT_DIR}"

if [[ "${SKIP_PROD_CONFIRM:-}" != "1" ]]; then
  echo "This will push migrations and Edge Functions to PRODUCTION: ${SUPABASE_PROD_REF}"
  read -r -p "Type PUSH PROD to continue: " confirmation
  if [[ "${confirmation}" != "PUSH PROD" ]]; then
    echo "Production deploy cancelled."
    exit 1
  fi
fi

echo "Linking Supabase production project: ${SUPABASE_PROD_REF}"
supabase link --project-ref "${SUPABASE_PROD_REF}"

echo "Migration status before push"
supabase migration list

echo "Pushing migrations to production"
supabase db push

echo "Deploying Edge Functions to production"
supabase functions deploy health-check
supabase functions deploy create-woovi-subscription
supabase functions deploy woovi-webhook
supabase functions deploy reconcile-woovi-subscription
supabase functions deploy cancel-woovi-subscription

echo "Migration status after push"
supabase migration list

echo "Production Supabase deploy finished."
