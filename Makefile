.PHONY: install-claude test-installation-claude install-crush test-installation-crush install-goose test-installation-goose install-kimi test-installation-kimi install-open-interpreter test-installation-open-interpreter install-qwen-code test-installation-qwen-code


UNAME_S := $(shell uname -s 2>/dev/null)

ifeq ($(OS),Windows_NT)
	OS_TYPE := windows
else ifeq ($(UNAME_S),Linux)
	OS_TYPE := linux
else ifeq ($(UNAME_S),Darwin)
	OS_TYPE := macos
else
	OS_TYPE := unknown
endif

export OS_TYPE


install-claude:
	$(MAKE) -f tools/claude/install.mk install

test-installation-claude:
	$(MAKE) -f tools/claude/install.mk test-installation

install-crush:
	$(MAKE) -f tools/crush/install.mk install

test-installation-crush:
	$(MAKE) -f tools/crush/install.mk test-installation

install-goose:
	$(MAKE) -f tools/goose/install.mk install

test-installation-goose:
	$(MAKE) -f tools/goose/install.mk test-installation

install-kimi:
	$(MAKE) -f tools/kimi/install.mk install

test-installation-kimi:
	$(MAKE) -f tools/kimi/install.mk test-installation

install-open-interpreter:
	$(MAKE) -f tools/open-interpreter/install.mk install

test-installation-open-interpreter:
	$(MAKE) -f tools/open-interpreter/install.mk test-installation

install-qwen-code:
	$(MAKE) -f tools/qwen-code/install.mk install

test-installation-qwen-code:
	$(MAKE) -f tools/qwen-code/install.mk test-installation
