#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"${ROOT_DIR}/scripts/supabase_push_dev.sh"

echo
echo "Dev deploy completed. Production is next."
read -r -p "Type PUSH PROD to continue with production: " confirmation
if [[ "${confirmation}" != "PUSH PROD" ]]; then
  echo "Production deploy skipped."
  exit 0
fi

SKIP_PROD_CONFIRM=1 "${ROOT_DIR}/scripts/supabase_push_prod.sh"
