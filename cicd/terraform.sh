#!/usr/bin/env bash
set -euo pipefail

# Hardcoded root for this env
TF_DIR="terraform/envs/dev"

if [ $# -lt 1 ]; then
  echo "Usage: $(basename "$0") <action> [extra terraform args...]"
  exit 1
fi

ACTION="$1"
shift

terraform -chdir="$TF_DIR" "$ACTION" "$@"
