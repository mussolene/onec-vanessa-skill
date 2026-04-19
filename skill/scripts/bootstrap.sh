#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v pwsh >/dev/null 2>&1; then
  echo "PowerShell (pwsh) is required to run bootstrap on this platform." >&2
  echo "Windows is the supported runtime target for actual 1C test execution." >&2
  exit 1
fi

exec pwsh -NoProfile -File "$SCRIPT_DIR/bootstrap.ps1" "$@"

