#!/usr/bin/env bash
# Launch Claude Code CLI backed by GLM-4.7-Flash via claude-code-proxy
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROXY_DIR="$SCRIPT_DIR/.claude-code-proxy"

# Load API key from .env
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

API_KEY="${CSCS_SERVING_API:?CSCS_SERVING_API not set in .env}"

# Export proxy env vars (no quotes around values)
export OPENAI_API_KEY="$API_KEY"
export OPENAI_BASE_URL="https://api.swissai.cscs.ch/v1"
export BIG_MODEL="zai-org/GLM-4.7-Flash"
export MIDDLE_MODEL="zai-org/GLM-4.7-Flash"
export SMALL_MODEL="zai-org/GLM-4.7-Flash"
export HOST="127.0.0.1"
export PORT="8082"
export LOG_LEVEL="WARNING"
export REQUEST_TIMEOUT="90"
export MAX_TOKENS_LIMIT="8192"
export MIN_TOKENS_LIMIT="4096"

# Start the proxy in the background
echo "=== Claude Code + GLM-4.7-Flash (via proxy) ==="
echo "Starting proxy on port $PORT..."
cd "$PROXY_DIR"
python start_proxy.py &>/dev/null &
PROXY_PID=$!

# Wait for proxy to be ready
for i in $(seq 1 20); do
    if curl -s "http://$HOST:$PORT/" > /dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

echo "Proxy:    http://$HOST:$PORT (PID $PROXY_PID)"
echo "Model:    all requests → GLM-4.7-Flash"
echo ""

# Launch Claude Code pointing at the proxy, with GLM identity
cd "$SCRIPT_DIR"
ANTHROPIC_BASE_URL="http://$HOST:$PORT" ANTHROPIC_API_KEY="dummy" claude \
    --system-prompt "You are GLM-4.7-Flash, a coding assistant powered by the Swiss AI Research Platform (CSCS). You help users with software engineering tasks: writing code, fixing bugs, refactoring, and explaining code. You have access to tools for reading files, writing files, editing files, running shell commands, and searching. Use these tools to assist the user." \
    "$@"
EXIT_CODE=$?

# Cleanup
kill "$PROXY_PID" 2>/dev/null || true
exit $EXIT_CODE
