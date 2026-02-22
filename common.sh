#!/usr/bin/env bash
# Shared helpers for Swiss AI Research Platform CLI launchers

CSCS_API_BASE="https://api.swissai.cscs.ch/v1"

# Load API key from .env
load_env() {
    local script_dir="$1"
    if [ -f "$script_dir/.env" ]; then
        set -a; source "$script_dir/.env"; set +a
    fi
    if [ -z "${CSCS_SERVING_API:-}" ]; then
        echo "Error: CSCS_SERVING_API not set in .env" >&2
        exit 1
    fi
}

# Query available chat models (excludes embedding/reranker models)
# Sets AVAILABLE_MODELS array
fetch_chat_models() {
    local raw
    raw=$(curl -s -H "Authorization: Bearer $CSCS_SERVING_API" "${CSCS_API_BASE}/models" 2>/dev/null)
    AVAILABLE_MODELS=()
    while IFS= read -r m; do
        [ -n "$m" ] && AVAILABLE_MODELS+=("$m")
    done < <(echo "$raw" | python3 -c "
import sys, json
from collections import OrderedDict

data = json.load(sys.stdin).get('data', [])

seen = OrderedDict()
for m in sorted(data, key=lambda x: x['id']):
    mid = m['id']
    if not any(s in mid.lower() for s in skip):
        if mid not in seen:
            seen[mid] = None
for mid in seen:
    print(mid)
" 2>/dev/null)
}

# Prompt user to pick a model. Sets MODEL variable.
# If $1 is provided, skip the prompt and use it directly.
pick_model() {
    if [ -n "${1:-}" ]; then
        MODEL="$1"
        return
    fi

    fetch_chat_models

    if [ ${#AVAILABLE_MODELS[@]} -eq 0 ]; then
        echo "Warning: Could not fetch models from API." >&2
        if [ "${IS_PIPE:-0}" -eq 1 ]; then
            echo "Error: non-interactive mode requires a model. Use -m/--model MODEL." >&2
            exit 1
        fi
        read -r -p "Enter model name manually: " MODEL < /dev/tty
        return
    fi

    # Non-interactive (piped) mode: require explicit model
    if [ "${IS_PIPE:-0}" -eq 1 ]; then
        echo "Error: piped input detected but no model specified. Use -m/--model MODEL." >&2
        echo "Available models:" >&2
        for m in "${AVAILABLE_MODELS[@]}"; do echo "  $m" >&2; done
        exit 1
    fi

    echo ""
    echo "Available models on CSCS:"
    for i in "${!AVAILABLE_MODELS[@]}"; do
        echo "  $((i + 1))) ${AVAILABLE_MODELS[$i]}"
    done
    echo ""
    read -r -p "Select model [1]: " choice < /dev/tty
    choice="${choice:-1}"

    local idx=$((choice - 1))
    if [ "$idx" -ge 0 ] && [ "$idx" -lt ${#AVAILABLE_MODELS[@]} ]; then
        MODEL="${AVAILABLE_MODELS[$idx]}"
    else
        echo "Invalid choice, using first model." >&2
        MODEL="${AVAILABLE_MODELS[0]}"
    fi
}
