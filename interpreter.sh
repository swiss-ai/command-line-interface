#!/usr/bin/env bash
# Launch Open Interpreter on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

pick_model "${1:-}"

# Build custom instructions from append file if it exists
CUSTOM_ARGS=()
APPEND_FILE="$SCRIPT_DIR/append-system-prompt.txt"
if [ -f "$APPEND_FILE" ]; then
    CUSTOM_ARGS=(--custom_instructions "$(cat "$APPEND_FILE")")
    echo "Prompt:   $APPEND_FILE"
fi

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
OI_LOG="$LOG_DIR/interpreter-debug.log"

echo "=== Open Interpreter + $MODEL ==="
echo "Endpoint: $CSCS_API_BASE"
echo "Model:    openai/$MODEL"
echo "Log:      $OI_LOG"
echo ""

exec interpreter \
    --model "openai/$MODEL" \
    --api_base "$CSCS_API_BASE" \
    --api_key "$CSCS_SERVING_API" \
    --context_window 128000 \
    --system_message "$(cat "$SCRIPT_DIR/_interpreter-agent/system-prompt.md")" \
    "${CUSTOM_ARGS[@]}" \
    --verbose \
    "${@:2}" 2> >(tee -a "$OI_LOG" >&2)
