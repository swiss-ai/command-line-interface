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

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

echo "=== Qwen Code + $MODEL ==="
echo "Endpoint: $OPENAI_BASE_URL"
echo "Model:    $OPENAI_MODEL"
echo "Log:      $LOG_DIR/qwen-openai.log"
echo ""

exec qwen \
    --openai-logging \
    --openai-logging-dir "$LOG_DIR/qwen-openai.log" \
    "${@:2}"
