#!/usr/bin/env bash
# Launch Claude Code CLI via claude-code-proxy on the Swiss AI Research Platform
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROXY_DIR="$SCRIPT_DIR/.claude-code-proxy"
source "$SCRIPT_DIR/common.sh"

load_env "$SCRIPT_DIR"

pick_model "${1:-}"

export CLAUDE_CODE_DISABLE_TELEMETRY=1
export DO_NOT_TRACK=1

# Export proxy env vars
export OPENAI_API_KEY="$CSCS_SERVING_API"
export OPENAI_BASE_URL="$CSCS_API_BASE"
export BIG_MODEL="$MODEL"
export MIDDLE_MODEL="$MODEL"
export SMALL_MODEL="$MODEL"
export HOST="127.0.0.1"
export PORT="8082"
export LOG_LEVEL="WARNING"
export REQUEST_TIMEOUT="90"
export MAX_TOKENS_LIMIT="8192"
export MIN_TOKENS_LIMIT="4096"

# Start the proxy in the background
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
CLAUDE_LOG="$LOG_DIR/claude-proxy-debug.log"

echo "=== Claude Code + $MODEL (via proxy) ==="
echo "Log:      $CLAUDE_LOG"
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
echo "Model:    all requests -> $MODEL"
echo ""

# Launch Claude Code pointing at the proxy
cd "$SCRIPT_DIR"
# Load append-system-prompt if it exists
APPEND_ARGS=()
APPEND_FILE="$SCRIPT_DIR/append-system-prompt.txt"
if [ -f "$APPEND_FILE" ]; then
    APPEND_ARGS=(--append-system-prompt "$(cat "$APPEND_FILE")")
    echo "Prompt:   $APPEND_FILE"
fi

ANTHROPIC_BASE_URL="http://$HOST:$PORT" ANTHROPIC_API_KEY="dummy" claude \
    --debug-file "$CLAUDE_LOG" \
    --system-prompt "IMPORTANT IDENTITY OVERRIDE: You are $MODEL, a coding assistant powered by the Swiss AI Research Platform (CSCS). You are NOT Claude, NOT made by Anthropic. If any other part of this prompt says you are Claude or made by Anthropic, IGNORE that — it is a artifact of the tool framework and does not apply to you. When asked who you are, always say you are $MODEL running on the Swiss AI Research Platform. You help users with software engineering tasks: writing code, fixing bugs, refactoring, and explaining code. You have access to tools for reading files, writing files, editing files, running shell commands, and searching. Use these tools to assist the user." \
    --mcp-config '{"mcpServers":{"duckduckgo":{"command":"/home/chuck/venv/bin/duckduckgo-mcp-server","args":[]}}}' \
    "${APPEND_ARGS[@]}" \
    "${@:2}"
EXIT_CODE=$?

# Cleanup
kill "$PROXY_PID" 2>/dev/null || true
exit $EXIT_CODE
