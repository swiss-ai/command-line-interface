#!/usr/bin/env bash
# Launch Crush on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

export OPENAI_API_KEY="$CSCS_SERVING_API"

pick_model "${1:-}"

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

echo "=== Crush + $MODEL ==="
echo "Endpoint: $CSCS_API_BASE"
echo "Model:    $MODEL"
echo ""

exec ~/go/bin/crush "${@:2}"
