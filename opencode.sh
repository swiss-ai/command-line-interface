#!/usr/bin/env bash
# Launch opencode on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

IS_PIPE=0
[ ! -t 0 ] && IS_PIPE=1
export IS_PIPE
info() { if [ "$IS_PIPE" -eq 1 ]; then echo "$@" >&2; else echo "$@"; fi; }

# Parse --model/-m flag; all other args are forwarded to opencode
MODEL_ARG=""
OPENCODE_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--model) MODEL_ARG="$2"; shift 2 ;;
        *) OPENCODE_ARGS+=("$1"); shift ;;
    esac
done

pick_model "$MODEL_ARG"

# opencode config reads SERVING_API_KEY from the environment
export SERVING_API_KEY="$CSCS_SERVING_API"

# Ensure the selected model is registered in opencode's config
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
if [ -f "$OPENCODE_CONFIG" ]; then
    python3 -c "
import json, sys
cfg = json.load(open('$OPENCODE_CONFIG'))
model = '$MODEL'
provider = cfg.setdefault('provider', {}).setdefault('swissai', {})
models = provider.setdefault('models', {})
if model not in models:
    models[model] = {'name': model}
    json.dump(cfg, open('$OPENCODE_CONFIG', 'w'), indent=2)
    print(f'Added model {model} to opencode config', file=sys.stderr)
"
fi

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

info "=== opencode + $MODEL ==="
info "Endpoint: $CSCS_API_BASE"
info "Model:    swissai/$MODEL"
info ""

if [ "$IS_PIPE" -eq 1 ]; then
    # Non-interactive: combine any extra args + stdin into one message
    STDIN_MSG="$(cat)"
    if [ ${#OPENCODE_ARGS[@]} -gt 0 ]; then
        COMBINED_MSG="${OPENCODE_ARGS[*]}"$'\n\n'"$STDIN_MSG"
    else
        COMBINED_MSG="$STDIN_MSG"
    fi
    exec opencode run \
        -m "swissai/$MODEL" \
        "$COMBINED_MSG"
else
    exec opencode \
        -m "swissai/$MODEL" \
        ${OPENCODE_ARGS[@]+"${OPENCODE_ARGS[@]}"}
fi
