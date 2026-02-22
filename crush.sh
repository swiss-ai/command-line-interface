#!/usr/bin/env bash
# Launch Crush on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

export OPENAI_API_KEY="$CSCS_SERVING_API"

IS_PIPE=0
[ ! -t 0 ] && IS_PIPE=1
export IS_PIPE
info() { if [ "$IS_PIPE" -eq 1 ]; then echo "$@" >&2; else echo "$@"; fi; }

# Parse --model/-m flag; all other args are forwarded to crush
MODEL_ARG=""
CRUSH_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--model) MODEL_ARG="$2"; shift 2 ;;
        *) CRUSH_ARGS+=("$1"); shift ;;
    esac
done

pick_model "$MODEL_ARG"

# Crush reads model from config, so patch it with the selected model
CRUSH_CONFIG="$HOME/.config/crush/crush.json"
if [ -f "$CRUSH_CONFIG" ]; then
    python3 -c "
import json, sys
cfg = json.load(open('$CRUSH_CONFIG'))
model = '$MODEL'
cfg['models']['large']['model'] = model
cfg['models']['small']['model'] = model
# Ensure model is in the provider's model list
provider = cfg['providers']['cscs']
ids = [m['id'] for m in provider['models']]
if model not in ids:
    provider['models'].append({
        'id': model,
        'name': model.split('/')[-1],
        'context_window': 131072,
        'default_max_tokens': 4096,
        'supports_tools': True
    })
json.dump(cfg, open('$CRUSH_CONFIG', 'w'), indent=2)
"
fi

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

info "=== Crush + $MODEL ==="
info "Endpoint: $CSCS_API_BASE"
info "Model:    $MODEL"
info ""

exec crush ${CRUSH_ARGS[@]+"${CRUSH_ARGS[@]}"}
