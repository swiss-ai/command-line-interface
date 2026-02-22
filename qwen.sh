#!/usr/bin/env bash
# Launch Qwen Code CLI on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

export OPENAI_API_KEY="$CSCS_SERVING_API"
export OPENAI_BASE_URL="$CSCS_API_BASE"

IS_PIPE=0
[ ! -t 0 ] && IS_PIPE=1
export IS_PIPE
info() { if [ "$IS_PIPE" -eq 1 ]; then echo "$@" >&2; else echo "$@"; fi; }

# Parse --model/-m flag; all other args are forwarded to qwen
MODEL_ARG=""
QWEN_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--model) MODEL_ARG="$2"; shift 2 ;;
        *) QWEN_ARGS+=("$1"); shift ;;
    esac
done

pick_model "$MODEL_ARG"

# Gotcha: --model flag uses Gemini API format. OPENAI_MODEL env var routes through
# the OpenAI chat/completions path instead.
export OPENAI_MODEL="$MODEL"

# Build system prompt: base + optional append file
AGENT_DIR="$SCRIPT_DIR/_qwen-agent"
SYSTEM_PROMPT="$AGENT_DIR/system-prompt.md"
APPEND_FILE="$SCRIPT_DIR/append-system-prompt.txt"
if [ -f "$APPEND_FILE" ]; then
    SYSTEM_PROMPT_TMP="$(mktemp "${TMPDIR:-/tmp}/tmp.XXXXXX")" && mv "$SYSTEM_PROMPT_TMP" "${SYSTEM_PROMPT_TMP}.md" && SYSTEM_PROMPT_TMP="${SYSTEM_PROMPT_TMP}.md"
    cat "$SYSTEM_PROMPT" > "$SYSTEM_PROMPT_TMP"
    printf '\n\n' >> "$SYSTEM_PROMPT_TMP"
    cat "$APPEND_FILE" >> "$SYSTEM_PROMPT_TMP"
    SYSTEM_PROMPT="$SYSTEM_PROMPT_TMP"
    info "Prompt:   $APPEND_FILE"
fi
export QWEN_SYSTEM_MD="$SYSTEM_PROMPT"

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

info "=== Qwen Code + $MODEL ==="
info "Endpoint: $OPENAI_BASE_URL"
info "Model:    $OPENAI_MODEL"
info "Log:      $LOG_DIR/qwen-openai.log"
info ""

exec qwen \
    --model "$MODEL" \
    --openai-logging \
    --openai-logging-dir "$LOG_DIR/qwen-openai.log" \
    ${QWEN_ARGS[@]+"${QWEN_ARGS[@]}"}
