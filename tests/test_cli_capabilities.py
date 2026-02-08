#!/usr/bin/env python3
"""
Per-CLI capability test suite for coding assistants on the CSCS GLM-4.7-Flash endpoint.

Tests each CLI (Aider, Kimi, Interpreter, Goose, Qwen) against specific capabilities
(file write, web fetch, web search, code execution, agentic multi-step) to validate
that each tool is correctly configured and functional.

Usage:
    python -m pytest tests/test_cli_capabilities.py -v --tb=short
    python -m pytest tests/test_cli_capabilities.py -v -k "TestGoose"
    python -m pytest tests/test_cli_capabilities.py -v -k "test_file_write"
"""

import os
import re
import subprocess
from pathlib import Path

import pytest
from dotenv import load_dotenv

# ── Configuration ─────────────────────────────────────────────────────────

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

API_BASE = "https://api.swissai.cscs.ch/v1"
API_KEY = os.environ.get("CSCS_SERVING_API", "")
MODEL_OPENAI = "openai/zai-org/GLM-4.7-Flash"  # aider/interpreter litellm format
MODEL_RAW = "zai-org/GLM-4.7-Flash"  # goose/qwen format

TIMEOUT = 90  # seconds per CLI invocation


# ── Helpers ───────────────────────────────────────────────────────────────

def _base_env():
    """Return a clean copy of os.environ with CSCS API credentials."""
    env = os.environ.copy()
    env["OPENAI_API_KEY"] = API_KEY
    env["OPENAI_API_BASE"] = API_BASE
    env["OPENAI_BASE_URL"] = API_BASE
    return env


def run_aider(workdir: str, message: str, *, timeout: int = TIMEOUT) -> dict:
    """Run aider non-interactively."""
    cmd = [
        "aider",
        "--model", MODEL_OPENAI,
        "--no-git",
        "--yes",
        "--no-pretty",
        "--no-stream",
        "--message", message,
    ]
    result = subprocess.run(
        cmd, cwd=workdir, capture_output=True, text=True,
        timeout=timeout, env=_base_env(),
    )
    return {"returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr}


def run_kimi(workdir: str, message: str, *, timeout: int = TIMEOUT) -> dict:
    """Run kimi by piping a prompt to stdin (exits on EOF)."""
    env = os.environ.copy()
    # Kimi uses its own config (~/.kimi/config.toml) — unset OpenAI vars to avoid conflict
    env.pop("OPENAI_API_KEY", None)
    env.pop("OPENAI_BASE_URL", None)
    result = subprocess.run(
        ["kimi", "--work-dir", workdir],
        input=message + "\n",
        cwd=workdir, capture_output=True, text=True,
        timeout=timeout, env=env,
    )
    return {"returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr}


def run_interpreter(workdir: str, message: str, *, timeout: int = TIMEOUT) -> dict:
    """Run Open Interpreter non-interactively (-y auto-runs code)."""
    cmd = [
        "interpreter",
        "-y",
        "--model", MODEL_OPENAI,
        "--api_base", API_BASE,
        "--api_key", API_KEY,
        "--context_window", "128000",
    ]
    result = subprocess.run(
        cmd, input=message + "\n",
        cwd=workdir, capture_output=True, text=True,
        timeout=timeout, env=_base_env(),
    )
    return {"returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr}


def run_goose(workdir: str, message: str, *, timeout: int = TIMEOUT) -> dict:
    """Run goose in non-interactive run mode."""
    env = _base_env()
    env["OPENAI_HOST"] = "https://api.swissai.cscs.ch"
    env["OPENAI_BASE_PATH"] = "v1/chat/completions"
    env["GOOSE_PROVIDER"] = "openai"
    env["GOOSE_MODEL"] = MODEL_RAW
    cmd = ["goose", "run", "-t", message]
    result = subprocess.run(
        cmd, cwd=workdir, capture_output=True, text=True,
        timeout=timeout, env=env,
    )
    return {"returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr}


def run_qwen(workdir: str, message: str, *, timeout: int = TIMEOUT) -> dict:
    """Run Qwen Code CLI in non-interactive prompt mode."""
    env = _base_env()
    env["OPENAI_MODEL"] = MODEL_RAW
    cmd = ["qwen", "-p", message, "-y"]
    result = subprocess.run(
        cmd, cwd=workdir, capture_output=True, text=True,
        timeout=timeout, env=env,
    )
    return {"returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr}


def combined_output(result: dict) -> str:
    """Combine stdout and stderr for assertion checks."""
    return (result["stdout"] + "\n" + result["stderr"]).lower()


# ── Prompts ───────────────────────────────────────────────────────────────

PROMPT_FILE_WRITE = (
    'Create a file called hello.txt containing exactly the text "swiss-ai-test" '
    "(no quotes). Do not create any other files."
)

PROMPT_WEB_FETCH = (
    "Fetch the URL https://httpbin.org/get using an HTTP request and show me "
    'the value of the "origin" field from the JSON response.'
)

PROMPT_WEB_SEARCH = (
    'Search the web for "Swiss AI Research Platform CSCS" and give me a '
    "one-paragraph summary of what you find."
)

PROMPT_CODE_EXEC = (
    "Run this Python command and tell me the result: python3 -c \"print(7 * 6)\""
)

PROMPT_AGENTIC = (
    "Do the following multi-step task:\n"
    "1. Create a file called nums.txt with the numbers 1 through 5, one per line.\n"
    "2. Read the file back.\n"
    "3. Calculate and report the sum of those numbers."
)


# ── Test Classes ──────────────────────────────────────────────────────────

@pytest.mark.timeout(TIMEOUT + 10)
class TestAider:
    """Aider — file write only (no web/code-exec/agentic capabilities)."""

    def test_file_write(self, tmp_path):
        result = run_aider(str(tmp_path), PROMPT_FILE_WRITE)
        hello = tmp_path / "hello.txt"
        assert hello.exists(), (
            f"hello.txt not created. rc={result['returncode']}\n"
            f"stdout: {result['stdout'][-500:]}\nstderr: {result['stderr'][-500:]}"
        )
        assert "swiss-ai-test" in hello.read_text()

    @pytest.mark.skip(reason="Aider has no web fetch capability")
    def test_web_fetch(self):
        pass

    @pytest.mark.skip(reason="Aider has no web search capability")
    def test_web_search(self):
        pass

    @pytest.mark.skip(reason="Aider has no code execution capability")
    def test_code_exec(self):
        pass

    @pytest.mark.skip(reason="Aider has no agentic capability")
    def test_agentic(self):
        pass


@pytest.mark.timeout(TIMEOUT + 10)
class TestKimi:
    """Kimi Code — file write and agentic (no web/code-exec)."""

    def test_file_write(self, tmp_path):
        result = run_kimi(str(tmp_path), PROMPT_FILE_WRITE)
        hello = tmp_path / "hello.txt"
        assert hello.exists(), (
            f"hello.txt not created. rc={result['returncode']}\n"
            f"stdout: {result['stdout'][-500:]}\nstderr: {result['stderr'][-500:]}"
        )
        assert "swiss-ai-test" in hello.read_text()

    @pytest.mark.skip(reason="Kimi has no web fetch capability")
    def test_web_fetch(self):
        pass

    @pytest.mark.skip(reason="Kimi has no web search capability")
    def test_web_search(self):
        pass

    @pytest.mark.skip(reason="Kimi has no code execution capability")
    def test_code_exec(self):
        pass

    def test_agentic(self, tmp_path):
        result = run_kimi(str(tmp_path), PROMPT_AGENTIC)
        nums = tmp_path / "nums.txt"
        output = combined_output(result)
        assert nums.exists(), (
            f"nums.txt not created. rc={result['returncode']}\n"
            f"stdout: {result['stdout'][-500:]}\nstderr: {result['stderr'][-500:]}"
        )
        assert "15" in output, f"Expected sum '15' in output:\n{output[-1000:]}"


@pytest.mark.timeout(TIMEOUT + 10)
class TestInterpreter:
    """Open Interpreter — all capabilities."""

    def test_file_write(self, tmp_path):
        result = run_interpreter(str(tmp_path), PROMPT_FILE_WRITE)
        hello = tmp_path / "hello.txt"
        assert hello.exists(), (
            f"hello.txt not created. rc={result['returncode']}\n"
            f"stdout: {result['stdout'][-500:]}\nstderr: {result['stderr'][-500:]}"
        )
        assert "swiss-ai-test" in hello.read_text()

    def test_web_fetch(self, tmp_path):
        result = run_interpreter(str(tmp_path), PROMPT_WEB_FETCH)
        output = combined_output(result)
        assert re.search(r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}", output), (
            f"No IP address found in output:\n{output[-1000:]}"
        )

    def test_web_search(self, tmp_path):
        result = run_interpreter(str(tmp_path), PROMPT_WEB_SEARCH)
        output = combined_output(result)
        assert "cscs" in output or "swiss" in output, (
            f"Expected 'cscs' or 'swiss' in output:\n{output[-1000:]}"
        )

    def test_code_exec(self, tmp_path):
        result = run_interpreter(str(tmp_path), PROMPT_CODE_EXEC)
        output = combined_output(result)
        assert "42" in output, f"Expected '42' in output:\n{output[-1000:]}"

    def test_agentic(self, tmp_path):
        result = run_interpreter(str(tmp_path), PROMPT_AGENTIC)
        nums = tmp_path / "nums.txt"
        output = combined_output(result)
        assert nums.exists(), (
            f"nums.txt not created. rc={result['returncode']}\n"
            f"stdout: {result['stdout'][-500:]}\nstderr: {result['stderr'][-500:]}"
        )
        assert "15" in output, f"Expected sum '15' in output:\n{output[-1000:]}"


@pytest.mark.timeout(TIMEOUT + 10)
class TestGoose:
    """Goose — file write, web fetch, code exec, agentic (no web search)."""

    def test_file_write(self, tmp_path):
        result = run_goose(str(tmp_path), PROMPT_FILE_WRITE)
        hello = tmp_path / "hello.txt"
        assert hello.exists(), (
            f"hello.txt not created. rc={result['returncode']}\n"
            f"stdout: {result['stdout'][-500:]}\nstderr: {result['stderr'][-500:]}"
        )
        assert "swiss-ai-test" in hello.read_text()

    def test_web_fetch(self, tmp_path):
        result = run_goose(str(tmp_path), PROMPT_WEB_FETCH)
        output = combined_output(result)
        assert re.search(r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}", output), (
            f"No IP address found in output:\n{output[-1000:]}"
        )

    @pytest.mark.skip(reason="Goose has no web search capability")
    def test_web_search(self):
        pass

    def test_code_exec(self, tmp_path):
        result = run_goose(str(tmp_path), PROMPT_CODE_EXEC)
        output = combined_output(result)
        assert "42" in output, f"Expected '42' in output:\n{output[-1000:]}"

    def test_agentic(self, tmp_path):
        result = run_goose(str(tmp_path), PROMPT_AGENTIC)
        nums = tmp_path / "nums.txt"
        output = combined_output(result)
        assert nums.exists(), (
            f"nums.txt not created. rc={result['returncode']}\n"
            f"stdout: {result['stdout'][-500:]}\nstderr: {result['stderr'][-500:]}"
        )
        assert "15" in output, f"Expected sum '15' in output:\n{output[-1000:]}"


@pytest.mark.timeout(TIMEOUT + 10)
class TestQwen:
    """Qwen Code — all capabilities."""

    def test_file_write(self, tmp_path):
        result = run_qwen(str(tmp_path), PROMPT_FILE_WRITE)
        hello = tmp_path / "hello.txt"
        assert hello.exists(), (
            f"hello.txt not created. rc={result['returncode']}\n"
            f"stdout: {result['stdout'][-500:]}\nstderr: {result['stderr'][-500:]}"
        )
        assert "swiss-ai-test" in hello.read_text()

    def test_web_fetch(self, tmp_path):
        result = run_qwen(str(tmp_path), PROMPT_WEB_FETCH)
        output = combined_output(result)
        assert re.search(r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}", output), (
            f"No IP address found in output:\n{output[-1000:]}"
        )

    def test_web_search(self, tmp_path):
        result = run_qwen(str(tmp_path), PROMPT_WEB_SEARCH)
        output = combined_output(result)
        assert "cscs" in output or "swiss" in output, (
            f"Expected 'cscs' or 'swiss' in output:\n{output[-1000:]}"
        )

    def test_code_exec(self, tmp_path):
        result = run_qwen(str(tmp_path), PROMPT_CODE_EXEC)
        output = combined_output(result)
        assert "42" in output, f"Expected '42' in output:\n{output[-1000:]}"

    def test_agentic(self, tmp_path):
        result = run_qwen(str(tmp_path), PROMPT_AGENTIC)
        nums = tmp_path / "nums.txt"
        output = combined_output(result)
        assert nums.exists(), (
            f"nums.txt not created. rc={result['returncode']}\n"
            f"stdout: {result['stdout'][-500:]}\nstderr: {result['stderr'][-500:]}"
        )
        assert "15" in output, f"Expected sum '15' in output:\n{output[-1000:]}"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
