#!/usr/bin/env bash
# Launch Open Interpreter with GLM-4.7-Flash on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load API key from .env
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

API_KEY="${CSCS_SERVING_API:?CSCS_SERVING_API not set in .env}"

echo "=== Open Interpreter + GLM-4.7-Flash ==="
echo "Endpoint: https://api.swissai.cscs.ch/v1"
echo "Model:    openai/zai-org/GLM-4.7-Flash"
echo ""

exec interpreter \
    --model "openai/zai-org/GLM-4.7-Flash" \
    --api_base "https://api.swissai.cscs.ch/v1" \
    --api_key "$API_KEY" \
    --context_window 128000 \
    "$@"
