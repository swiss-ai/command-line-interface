#!/usr/bin/env bash
# Launch Goose on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

export OPENAI_API_KEY="$CSCS_SERVING_API"
export OPENAI_HOST="https://api.swissai.cscs.ch"
export OPENAI_BASE_PATH="v1/chat/completions"
export GOOSE_PROVIDER="openai"

pick_model "${1:-}"

export GOOSE_MODEL="$MODEL"

# Build system prompt: base + optional append file
AGENT_DIR="$SCRIPT_DIR/_goose-agent"
SYSTEM_PROMPT="$AGENT_DIR/system-prompt.md"
APPEND_FILE="$SCRIPT_DIR/append-system-prompt.txt"
if [ -f "$APPEND_FILE" ]; then
    SYSTEM_PROMPT_TMP="$(mktemp --suffix=.md)"
    cat "$SYSTEM_PROMPT" > "$SYSTEM_PROMPT_TMP"
    printf '\n\n' >> "$SYSTEM_PROMPT_TMP"
    cat "$APPEND_FILE" >> "$SYSTEM_PROMPT_TMP"
    SYSTEM_PROMPT="$SYSTEM_PROMPT_TMP"
    echo "Prompt:   $APPEND_FILE"
fi
export GOOSE_SYSTEM_PROMPT_FILE_PATH="$SYSTEM_PROMPT"

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

echo "=== Goose + $MODEL ==="
echo "Endpoint: $CSCS_API_BASE"
echo "Model:    $MODEL"
echo "Log:      $LOG_DIR/goose-debug.log"
echo ""

exec goose session --debug "${@:2}" 2> >(tee -a "$LOG_DIR/goose-debug.log" >&2)
