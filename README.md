# Swiss AI Command Line Interface (experimental)

Command line coding assistants configured for the [Swiss AI Research Platform (CSCS)](https://serving.swissai.svc.cscs.ch/), using the OpenAI-compatible API at `https://api.swissai.svc.cscs.ch/v1`.

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
git clone https://github.com/swiss-ai/command-line-interface.git
cd command-line-interface
```

### 2. API key

Export your CSCS serving API key (most setups already have it):

```bash
export SWISSAI_RESEARCH_API_KEY=<your-key>
```

Or put `SWISSAI_RESEARCH_API_KEY=<your-key>` in a `.env` file in this directory (git-ignored). The older `CSCS_SERVING_API` name is still accepted.

Get your key from [serving.swissai.svc.cscs.ch](https://serving.swissai.svc.cscs.ch/). No VPN required.

To use another endpoint, set `CSCS_API_BASE` (default `https://api.swissai.svc.cscs.ch/v1`). Inside OpenSandbox pods use `https://api-test.swissai.svc.cscs.ch/v1`.

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
curl -fsSL https://opencode.ai/install | bash

```

### 4. Kimi config

Kimi needs a config file at `~/.kimi/config.toml`:

```toml
default_model = "glm-flash"

[providers.swissai]
type = "openai_legacy"
base_url = "https://api.swissai.svc.cscs.ch/v1"
api_key = "<your-key>"

[models.glm-flash]
provider = "swissai"
model = "zai-org/GLM-4.7-Flash"
max_context_size = 128000
```

**Gotcha:** Kimi overrides the config file API key if `OPENAI_API_KEY` is set in your environment. The launch script handles this by unsetting it.

## OpenCode notes

`./opencode.sh [model] [opencode args]` regenerates `~/.config/opencode/opencode.json` on every run (back it up if you have your own).

- **Context limits**: each model's window is read from `--max-model-len` in its `/v1/models` metadata and written as an OpenCode `limit` (a quarter reserved for output). Without it OpenCode requests `max_tokens=32000`, which small-context models (e.g. 16k) reject.
- **Minimal prompt**: `OPENCODE_DISABLE_CLAUDE_CODE=1` is set by default, so OpenCode does not load `~/.claude` (`CLAUDE.md`, skills). A large skills folder can add 10k+ tokens to every request. Set `OPENCODE_DISABLE_CLAUDE_CODE=0` to keep them.
- OpenCode's own system prompt plus tool definitions is about 7.5k tokens.
- Non-interactive: `./opencode.sh <model> run -- "<prompt>"`.

## Tests

Run the capability tests against the live CSCS API:

```bash
python -m pytest tests/test_cli_capabilities.py -v --tb=short
```

To test a single CLI:

```bash
python -m pytest tests/test_cli_capabilities.py -v -k "TestGoose"
```
