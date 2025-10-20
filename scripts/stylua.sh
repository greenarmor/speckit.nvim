#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_PATH="$ROOT_DIR/.cache/stylua/stylua"

if ! [ -x "$BIN_PATH" ]; then
  "$ROOT_DIR/scripts/install-stylua.sh"
fi

exec "$BIN_PATH" "$@"
