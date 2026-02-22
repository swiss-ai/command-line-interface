.PHONY: install install-linux install-macos install-windows test-installation

install: install-$(OS_TYPE)

install-linux:
	curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash

install-macos:
	curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash

install-windows:
	curl -L -o download_cli.ps1 https://raw.githubusercontent.com/block/goose/main/download_cli.ps1
	powershell -NoProfile -ExecutionPolicy Bypass -Command ".\download_cli.ps1"

test-installation:
	@echo "TODO"
