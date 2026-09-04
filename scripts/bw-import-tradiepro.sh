#!/usr/bin/env bash
# Import TradiePro gitignored env files into a Bitwarden collection.
# Run in YOUR terminal after: export BW_SESSION="$(bw unlock --raw)"
# Usage: ./scripts/bw-import-tradiepro.sh 'Your collection name'

set -euo pipefail

collection="${1:-}"
if [[ -z "$collection" ]]; then
  echo "Usage: $0 'Collection name'" >&2
  echo "First: export BW_SESSION=\"\$(bw unlock --raw)\"" >&2
  echo "Then:  $0 --list" >&2
  exit 1
fi

here="$(cd "$(dirname "$0")" && pwd)"
root="${TRADIEPRO_ROOT:-$HOME/development/tradie_pro_refactor/tradie-pro-refactor}"

if [[ "$collection" == "--list" ]]; then
  exec python3 "$here/bw-import-env.py" --list-collections
fi

python3 "$here/bw-import-env.py" \
  --collection "$collection" \
  --item-prefix "tradiepro/" \
  --file "$root/.env.local" \
  --file "$root/apps/api/.env" \
  --file "$root/apps/web/.env.local"
