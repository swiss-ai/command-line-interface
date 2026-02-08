#!/usr/bin/env bash
# Launch aider on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

export OPENAI_API_BASE="$CSCS_API_BASE"
export OPENAI_BASE_URL="$CSCS_API_BASE"
export OPENAI_API_KEY="$CSCS_SERVING_API"

pick_model "${1:-}"

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

echo "=== Aider + $MODEL ==="
echo "Endpoint: $OPENAI_API_BASE"
echo "Model:    $MODEL"
echo "Logs:     $LOG_DIR/aider-llm.log, $LOG_DIR/aider-chat.md"
echo ""

exec aider --model "openai/$MODEL" \
    --llm-history-file "$LOG_DIR/aider-llm.log" \
    --chat-history-file "$LOG_DIR/aider-chat.md" \
    "${@:2}"
