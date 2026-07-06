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

call_health_check() {
  local name="$1"
  local url="$2"
  local key="$3"

  if [[ -z "${url}" || -z "${key}" ]]; then
    echo "Skipping ${name}: health URL/key not configured."
    return 0
  fi

  echo "Calling ${name} health-check"
  curl --fail --silent --show-error \
    --header "Authorization: Bearer ${key}" \
    --header "apikey: ${key}" \
    "${url}" >/dev/null
  echo "${name} health-check ok"
}

call_health_check "dev" "${SUPABASE_DEV_HEALTH_URL:-}" "${SUPABASE_DEV_HEALTH_KEY:-${SUPABASE_DEV_ANON_KEY:-}}"
call_health_check "prod" "${SUPABASE_PROD_HEALTH_URL:-}" "${SUPABASE_PROD_HEALTH_KEY:-${SUPABASE_PROD_ANON_KEY:-}}"
