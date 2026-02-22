.PHONY: install test-installation

install:
	pip install kimi-cli

test-installation:
	kimi-cli --version
