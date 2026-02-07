# Swiss AI CLI

CLI coding assistants configured for the [Swiss AI Research Platform (CSCS)](https://serving.swissai.cscs.ch/), using **GLM-4.7-Flash** via the OpenAI-compatible API at `https://api.swissai.cscs.ch/v1`.

## Available CLIs

| Script | CLI | How it connects | Best for |
|--------|-----|----------------|----------|
| `./start-aider.sh` | [Aider](https://aider.chat/) | Native OpenAI-compat | General coding, git-aware edits |
| `./start-kimi.sh` | [Kimi Code](https://github.com/MoonshotAI/kimi-cli) | Native OpenAI-compat (`openai_legacy`) | Agentic coding with tool calling |
| `./start-interpreter.sh` | [Open Interpreter](https://github.com/openinterpreter/open-interpreter) | Native OpenAI-compat | Running code, system automation |
| `./start-claude-glm.sh` | [Claude Code](https://claude.com/claude-code) + [proxy](https://github.com/fuergaosi233/claude-code-proxy) | Via translation proxy | Claude Code UX with GLM backend |

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
# Aider (recommended)
pip install aider-chat

# Kimi Code CLI (requires Python 3.12+)
pip install kimi-cli

# Open Interpreter
pip install open-interpreter

# Claude Code (npm) + proxy (for ./start-claude-glm.sh)
npm install -g @anthropic-ai/claude-code
git clone https://github.com/fuergaosi233/claude-code-proxy .claude-code-proxy
pip install -r .claude-code-proxy/requirements.txt
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

## Usage

```bash
./start-aider.sh                # interactive aider session
./start-kimi.sh                 # interactive kimi session
./start-interpreter.sh          # interactive open-interpreter session
./start-claude-glm.sh           # claude code with GLM backend (starts proxy automatically)
```

### Passing extra arguments

```bash
./start-aider.sh openai/swiss-ai/Apertus-70B-Instruct-2509   # use a different model
./start-kimi.sh --verbose                                      # debug output
./start-claude-glm.sh -p "explain this codebase"               # headless mode
```

## Available Models

| Model | Type | Notes |
|-------|------|-------|
| `zai-org/GLM-4.7-Flash` | Chat (MoE 30B/3B active) | Best for coding. SWE-bench 59.2%, tool-use 79.5% |
| `swiss-ai/Apertus-70B-Instruct-2509` | Chat (70B dense) | General-purpose, weaker at code |
| `swiss-ai/Apertus-8B-Instruct-2509` | Chat (8B dense) | Too small for coding |
| `Snowflake/snowflake-arctic-embed-l-v2.0` | Embedding | For RAG pipelines |
| `BAAI/bge-reranker-v2-m3` | Reranker | For RAG pipelines |

Check live availability:

```bash
curl -s -H "Authorization: Bearer $CSCS_SERVING_API" https://api.swissai.cscs.ch/v1/models | python3 -m json.tool
```

## Tests

The test suite validates API connectivity, code generation, aider integration, and tool/function calling:

```bash
pip install pytest requests python-dotenv
python -m pytest tests/test_glm_coding.py -v
```

## Architecture

```
.env                    # API key (not committed)
.aider.conf.yml         # Aider config → Swiss AI API + GLM-4.7-Flash
.claude-code-proxy/     # Translation proxy for Claude Code (not committed, clone separately)
start-aider.sh          # Loads .env, sets OPENAI_API_BASE, launches aider
start-kimi.sh           # Unsets conflicting env vars, launches kimi (uses ~/.kimi/config.toml)
start-interpreter.sh    # Loads .env, passes API config via CLI flags
start-claude-glm.sh     # Loads .env, starts proxy, launches claude code pointed at proxy
tests/test_glm_coding.py  # pytest suite: API, aider integration, tool calling
```

### Why multiple CLIs?

Each has different strengths:

- **Aider** — most mature, best git integration, no proxy needed, works with any model
- **Kimi Code** — native tool calling (WriteFile, ReadFile, etc.), agentic planning
- **Open Interpreter** — executes code directly, good for data tasks and automation
- **Claude Code** — powerful agentic UX, but requires a proxy for non-Anthropic models
