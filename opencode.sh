#!/usr/bin/env bash
# Launch OpenCode CLI on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

export SWISSAI_API_KEY="$CSCS_SERVING_API"

pick_model "${1:-}"

# Build instructions list: base system prompt + optional append file
AGENT_DIR="$SCRIPT_DIR/_opencode-agent"
INSTRUCTIONS=("$AGENT_DIR/system-prompt.md")
APPEND_FILE="$SCRIPT_DIR/append-system-prompt.txt"
if [ -f "$APPEND_FILE" ]; then
    INSTRUCTIONS+=("$APPEND_FILE")
    echo "Prompt:   $APPEND_FILE"
fi

# OpenCode reads its provider/model setup from ~/.config/opencode/opencode.json.
# Regenerate it on every run so it always points at the selected model.
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

export OPENCODE_CONFIG_PATH="$OPENCODE_CONFIG_DIR/opencode.json"
export OPENCODE_BASE_URL="$CSCS_API_BASE"
export OPENCODE_MODEL="$MODEL"
export OPENCODE_INSTRUCTIONS="$(printf '%s\n' "${INSTRUCTIONS[@]}")"

python3 -c "
import json, os

model = os.environ['OPENCODE_MODEL']
instructions = [l for l in os.environ['OPENCODE_INSTRUCTIONS'].splitlines() if l]

cfg = {
    '\$schema': 'https://opencode.ai/config.json',
    'provider': {
        'swissai': {
            'npm': '@ai-sdk/openai-compatible',
            'name': 'Swiss AI (CSCS)',
            'options': {
                'baseURL': os.environ['OPENCODE_BASE_URL'],
                'apiKey': '{env:SWISSAI_API_KEY}',
            },
            'models': {
                model: {'name': model},
            },
        },
    },
    'model': f'swissai/{model}',
    'instructions': instructions,
}
json.dump(cfg, open(os.environ['OPENCODE_CONFIG_PATH'], 'w'), indent=2)
"

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

echo "=== OpenCode + $MODEL ==="
echo "Endpoint: $CSCS_API_BASE"
echo "Model:    swissai/$MODEL"
echo "Config:   $OPENCODE_CONFIG_PATH"
echo ""

exec opencode "${@:2}"
