.PHONY: install install-linux install-macos install-windows test-installation

install: install-$(OS_TYPE)

install-linux:
	curl -fsSL https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen.sh | bash

install-macos:
	curl -fsSL https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen.sh | bash

install-windows:
	npm install -g @qwen-code/qwen-code@latest

test-installation:
	qwen --version