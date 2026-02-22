.PHONY: install test-installation

install:
	uv pip install kimi-cli

test-installation:
	kimi-cli --version
