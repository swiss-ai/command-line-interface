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

IS_PIPE=0
[ ! -t 0 ] && IS_PIPE=1
export IS_PIPE
info() { if [ "$IS_PIPE" -eq 1 ]; then echo "$@" >&2; else echo "$@"; fi; }

# Parse --model/-m flag; all other args are forwarded to kimi
MODEL_ARG=""
KIMI_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--model) MODEL_ARG="$2"; shift 2 ;;
        *) KIMI_ARGS+=("$1"); shift ;;
    esac
done

pick_model "$MODEL_ARG"

# Override kimi's model with the selected one
KIMI_CONFIG="default_model = \"selected\"

[providers.swissai]
type = \"openai_legacy\"
base_url = \"$CSCS_API_BASE\"
api_key = \"$CSCS_SERVING_API\"

[models.selected]
provider = \"swissai\"
model = \"$MODEL\"
max_context_size = 128000
"

# Append extra context from file into system prompt if it exists
AGENT_DIR="$SCRIPT_DIR/_kimi-agent"
SYSTEM_PROMPT="$AGENT_DIR/system-prompt.md"
APPEND_FILE="$SCRIPT_DIR/append-system-prompt.txt"
if [ -f "$APPEND_FILE" ]; then
    # Create a temp copy with appended content
    SYSTEM_PROMPT_TMP="$(mktemp)"
    cat "$SYSTEM_PROMPT" > "$SYSTEM_PROMPT_TMP"
    printf '\n\n' >> "$SYSTEM_PROMPT_TMP"
    cat "$APPEND_FILE" >> "$SYSTEM_PROMPT_TMP"
    # Point agent at the temp file
    AGENT_TMP="$(mktemp "${TMPDIR:-/tmp}/tmp.XXXXXX")" && mv "$AGENT_TMP" "${AGENT_TMP}.yaml" && AGENT_TMP="${AGENT_TMP}.yaml"
    cat > "$AGENT_TMP" <<YAML
version: 1
agent:
  extend: default
  system_prompt_path: $SYSTEM_PROMPT_TMP
  system_prompt_args:
    ROLE_ADDITIONAL: ""
YAML
    AGENT_FILE="$AGENT_TMP"
    info "Prompt:   $APPEND_FILE"
else
    AGENT_FILE="$AGENT_DIR/agent.yaml"
fi

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
KIMI_LOG="$LOG_DIR/kimi-debug.log"

info "=== Kimi Code CLI + $MODEL ==="
info "Config:   ~/.kimi/config.toml"
info "Provider: swissai (openai_legacy)"
info "Model:    $MODEL"
info "Log:      $KIMI_LOG"
info ""

exec kimi --config "$KIMI_CONFIG" --agent-file "$AGENT_FILE" --debug ${KIMI_ARGS[@]+"${KIMI_ARGS[@]}"} 2> >(tee -a "$KIMI_LOG" >&2)
