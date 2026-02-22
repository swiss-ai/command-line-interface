#!/usr/bin/env bash
# Launch Open Interpreter on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

IS_PIPE=0
[ ! -t 0 ] && IS_PIPE=1
export IS_PIPE
info() { if [ "$IS_PIPE" -eq 1 ]; then echo "$@" >&2; else echo "$@"; fi; }

# Parse --model/-m flag; all other args are forwarded to interpreter
MODEL_ARG=""
INTERP_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--model) MODEL_ARG="$2"; shift 2 ;;
        *) INTERP_ARGS+=("$1"); shift ;;
    esac
done

pick_model "$MODEL_ARG"

# Build custom instructions from append file if it exists
CUSTOM_ARGS=()
APPEND_FILE="$SCRIPT_DIR/append-system-prompt.txt"
if [ -f "$APPEND_FILE" ]; then
    CUSTOM_ARGS=(--custom_instructions "$(cat "$APPEND_FILE")")
    info "Prompt:   $APPEND_FILE"
fi

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
OI_LOG="$LOG_DIR/interpreter-debug.log"

info "=== Open Interpreter + $MODEL ==="
info "Endpoint: $CSCS_API_BASE"
info "Model:    openai/$MODEL"
info "Log:      $OI_LOG"
info ""

exec interpreter \
    --model "openai/$MODEL" \
    --api_base "$CSCS_API_BASE" \
    --api_key "$CSCS_SERVING_API" \
    --context_window 128000 \
    --system_message "$(cat "$SCRIPT_DIR/_interpreter-agent/system-prompt.md")" \
    ${CUSTOM_ARGS[@]+"${CUSTOM_ARGS[@]}"} \
    --verbose \
    ${INTERP_ARGS[@]+"${INTERP_ARGS[@]}"} 2> >(tee -a "$OI_LOG" >&2)
