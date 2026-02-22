.PHONY: install install-linux install-macos install-windows test-installation

install: install-$(OS_TYPE)

install-linux:
	curl -fsSL https://claude.ai/install.sh | bash

install-macos:
	curl -fsSL https://claude.ai/install.sh | bash

install-windows:
	npm install -g @anthropic-ai/claude-code

test-installation:
	claude --version
