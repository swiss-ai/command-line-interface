#!/usr/bin/env bash
# Launch Kimi Code CLI on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

# Kimi's openai_legacy provider silently overrides config if OPENAI_API_KEY is set.
# Unset it so the ~/.kimi/config.toml values are used instead.
unset OPENAI_API_KEY
unset OPENAI_BASE_URL

pick_model "${1:-}"

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
KIMI_LOG="$LOG_DIR/kimi-debug.log"

echo "=== Kimi Code CLI + $MODEL ==="
echo "Config:   ~/.kimi/config.toml"
echo "Provider: swissai (openai_legacy)"
echo "Model:    $MODEL"
echo "Log:      $KIMI_LOG"
echo ""

exec kimi --debug "$@" 2> >(tee -a "$KIMI_LOG" >&2)
