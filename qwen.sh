#!/usr/bin/env bash
# Launch Qwen Code CLI on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

export OPENAI_API_KEY="$CSCS_SERVING_API"
export OPENAI_BASE_URL="$CSCS_API_BASE"

pick_model "${1:-}"

# Gotcha: --model flag uses Gemini API format. OPENAI_MODEL env var routes through
# the OpenAI chat/completions path instead.
export OPENAI_MODEL="$MODEL"

# Build system prompt: base + optional append file
AGENT_DIR="$SCRIPT_DIR/_qwen-agent"
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
export QWEN_SYSTEM_MD="$SYSTEM_PROMPT"

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

echo "=== Qwen Code + $MODEL ==="
echo "Endpoint: $OPENAI_BASE_URL"
echo "Model:    $OPENAI_MODEL"
echo "Log:      $LOG_DIR/qwen-openai.log"
echo ""

exec qwen \
    --model "$MODEL" \
    --openai-logging \
    --openai-logging-dir "$LOG_DIR/qwen-openai.log" \
    "${@:2}"
