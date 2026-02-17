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
    AGENT_TMP="$(mktemp --suffix=.yaml)"
    cat > "$AGENT_TMP" <<YAML
version: 1
agent:
  extend: default
  system_prompt_path: $SYSTEM_PROMPT_TMP
  system_prompt_args:
    ROLE_ADDITIONAL: ""
YAML
    AGENT_FILE="$AGENT_TMP"
    echo "Prompt:   $APPEND_FILE"
else
    AGENT_FILE="$AGENT_DIR/agent.yaml"
fi

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
KIMI_LOG="$LOG_DIR/kimi-debug.log"

echo "=== Kimi Code CLI + $MODEL ==="
echo "Config:   ~/.kimi/config.toml"
echo "Provider: swissai (openai_legacy)"
echo "Model:    $MODEL"
echo "Log:      $KIMI_LOG"
echo ""

exec kimi --config "$KIMI_CONFIG" --agent-file "$AGENT_FILE" --debug "${@:2}" 2> >(tee -a "$KIMI_LOG" >&2)
