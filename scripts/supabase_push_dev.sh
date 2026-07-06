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

echo "Migration status before push"
supabase migration list

echo "Pushing migrations to dev"
supabase db push

echo "Deploying Edge Functions to dev"
supabase functions deploy health-check
supabase functions deploy create-woovi-subscription
supabase functions deploy woovi-webhook
supabase functions deploy reconcile-woovi-subscription
supabase functions deploy cancel-woovi-subscription

echo "Migration status after push"
supabase migration list

echo "Dev Supabase deploy finished."
