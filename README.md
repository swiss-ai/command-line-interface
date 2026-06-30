# Swiss AI Command Line Interface (experimental)

Command line coding assistants configured for the [Swiss AI Research Platform (CSCS)](https://serving.swissai.cscs.ch/), using the OpenAI-compatible API at `https://api.swissai.cscs.ch/v1`.

## Available CLIs

| Script | CLI |
|--------|-----|
| `./claude-code.sh` | [Claude Code](https://claude.com/claude-code) + [proxy](https://github.com/fuergaosi233/claude-code-proxy) (recommended) |
| `./goose.sh` | [Goose](https://github.com/block/goose) |
| `./kimi.sh` | [Kimi Code](https://github.com/MoonshotAI/kimi-cli) |
| `./qwen.sh` | [Qwen Code](https://github.com/QwenLM/qwen-code) |
| `./interpreter.sh` | [Open Interpreter](https://github.com/openinterpreter/open-interpreter) |
| `./opencode.sh` | [OpenCode](https://github.com/anomalyco/opencode) |

## Setup

### 1. Clone

```bash
git clone https://github.com/swiss-ai/swiss-ai-cli.git
cd swiss-ai-cli
```

### 2. API key

Create a `.env` file with your CSCS serving API key:

```bash
echo 'CSCS_SERVING_API=<your-key>' > .env
```

Get your key from [serving.swissai.cscs.ch](https://serving.swissai.cscs.ch/). No VPN required.

### 3. Install CLIs

```bash
# Claude Code (recommended, npm) + proxy
npm install -g @anthropic-ai/claude-code
git clone https://github.com/fuergaosi233/claude-code-proxy .claude-code-proxy
pip install -r .claude-code-proxy/requirements.txt

# Goose
curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash

# Kimi Code CLI (requires Python 3.12+)
pip install kimi-cli

# Qwen Code (requires Node.js 20+)
npm install -g @qwen-code/qwen-code@latest

# Open Interpreter
pip install open-interpreter

# OpenCode 
export VERSION=1.16.2 && curl -fsSL https://opencode.ai/install | bash

```

### 4. Kimi config

Kimi needs a config file at `~/.kimi/config.toml`:

```toml
default_model = "glm-flash"

[providers.swissai]
type = "openai_legacy"
base_url = "https://api.swissai.cscs.ch/v1"
api_key = "<your-key>"

[models.glm-flash]
provider = "swissai"
model = "zai-org/GLM-4.7-Flash"
max_context_size = 128000
```

**Gotcha:** Kimi overrides the config file API key if `OPENAI_API_KEY` is set in your environment. The launch script handles this by unsetting it.

## Tests

Run the capability tests against the live CSCS API:

```bash
python -m pytest tests/test_cli_capabilities.py -v --tb=short
```

To test a single CLI:

```bash
python -m pytest tests/test_cli_capabilities.py -v -k "TestGoose"
```
