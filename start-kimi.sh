#!/usr/bin/env bash
# Launch Kimi Code CLI with GLM-4.7-Flash on the Swiss AI Research Platform
set -euo pipefail

# Kimi's openai_legacy provider silently overrides config if OPENAI_API_KEY is set.
# Unset it so the ~/.kimi/config.toml values are used instead.
unset OPENAI_API_KEY
unset OPENAI_BASE_URL

echo "=== Kimi Code CLI + GLM-4.7-Flash ==="
echo "Config:   ~/.kimi/config.toml"
echo "Provider: swissai (openai_legacy)"
echo "Model:    zai-org/GLM-4.7-Flash"
echo ""

exec kimi "$@"
