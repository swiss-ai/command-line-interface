#!/usr/bin/env bash
# Launch aider with GLM-4.7-Flash on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load API key from .env
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

export OPENAI_API_BASE="https://api.swissai.cscs.ch/v1"
export OPENAI_API_KEY="${CSCS_SERVING_API:?CSCS_SERVING_API not set in .env}"

MODEL="${1:-openai/zai-org/GLM-4.7-Flash}"

echo "=== Aider + GLM-4.7-Flash ==="
echo "Endpoint: $OPENAI_API_BASE"
echo "Model:    $MODEL"
echo ""

exec aider --model "$MODEL" "${@:2}"
