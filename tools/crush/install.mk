.PHONY: install test-installation

install:
	npm install -g @charmland/crush

test-installation:
	crush --version
