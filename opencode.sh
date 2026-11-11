#!/usr/bin/env bash
# Launch OpenCode CLI on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

export SWISSAI_API_KEY="$CSCS_SERVING_API"
# Keep the prompt minimal: by default OpenCode also loads ~/.claude (CLAUDE.md,
# skills), which can add several thousand tokens and overflow small-context
# models. Set OPENCODE_DISABLE_CLAUDE_CODE=0 to keep them.
export OPENCODE_DISABLE_CLAUDE_CODE="${OPENCODE_DISABLE_CLAUDE_CODE:-1}"

# Under WSL, `opencode` execs into a native Windows binary, which does NOT
# inherit WSL-side env vars unless they're listed in WSLENV.
if [ -n "${WSL_DISTRO_NAME:-}" ]; then
    export WSLENV="${WSLENV:+$WSLENV:}SWISSAI_API_KEY"
fi

pick_model "${1:-}"

# Fetch the full model list so opencode.json exposes all of them, not just $MODEL
fetch_chat_models
if [ ${#AVAILABLE_MODELS[@]} -eq 0 ]; then
    AVAILABLE_MODELS=("$MODEL")
fi

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
# Under WSL, `opencode` is the native Windows binary, which resolves its home
# via the Windows user profile, not WSL's $HOME -- write the config there too.
CONFIG_HOME="$HOME"
if [ -n "${WSL_DISTRO_NAME:-}" ] && command -v wslpath >/dev/null 2>&1; then
    WIN_USERPROFILE="$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')"
    if [ -n "$WIN_USERPROFILE" ]; then
        CONFIG_HOME="$(wslpath "$WIN_USERPROFILE")"
    fi
fi
OPENCODE_CONFIG_DIR="$CONFIG_HOME/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

export OPENCODE_CONFIG_PATH="$OPENCODE_CONFIG_DIR/opencode.json"
export OPENCODE_BASE_URL="$CSCS_API_BASE"
export OPENCODE_MODEL="$MODEL"
export OPENCODE_INSTRUCTIONS="$(printf '%s\n' "${INSTRUCTIONS[@]}")"
export OPENCODE_AVAILABLE_MODELS="$(printf '%s\n' "${AVAILABLE_MODELS[@]}")"
# Model metadata, to size each model's context window (see limits() below)
export OPENCODE_MODELS_JSON="$(curl -s -H "Authorization: Bearer $CSCS_SERVING_API" "${CSCS_API_BASE}/models" 2>/dev/null || true)"

python3 -c "
import json, os

model = os.environ['OPENCODE_MODEL']
instructions = [l for l in os.environ['OPENCODE_INSTRUCTIONS'].splitlines() if l]
available_models = [l for l in os.environ['OPENCODE_AVAILABLE_MODELS'].splitlines() if l]

# Without a limit OpenCode requests max_tokens=32000, which vLLM rejects for
# models served with a smaller --max-model-len (e.g. 16k). Read that value from
# the model's framework_args label and reserve an eighth of it for output.
# No 'input' limit on purpose: with one, OpenCode compacts at input - output
# (8k for a 16k model, about the size of its own prompt).
def limits(model_id):
    try:
        data = json.loads(os.environ.get('OPENCODE_MODELS_JSON') or '{}').get('data', [])
    except ValueError:
        return None
    for m in data:
        args = ((m.get('labels') or {}).get('framework_args') or '').split()
        if m.get('id') == model_id and '--max-model-len' in args:
            try:
                context = int(args[args.index('--max-model-len') + 1])
            except (IndexError, ValueError):
                return None
            output = min(max(context // 8, 2048), 32000)
            return {'context': context, 'output': output}
    return None

def model_entry(m):
    entry = {'name': m}
    limit = limits(m)
    if limit:
        entry['limit'] = limit
    return entry

cfg = {
    '\$schema': 'https://opencode.ai/config.json',
    'autoupdate': False,
    'provider': {
        'swissai': {
            'npm': '@ai-sdk/openai-compatible',
            'name': 'Swiss AI (CSCS)',
            'options': {
                'baseURL': os.environ['OPENCODE_BASE_URL'],
                'apiKey': '{env:SWISSAI_API_KEY}',
            },
            'models': {m: model_entry(m) for m in available_models},
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
