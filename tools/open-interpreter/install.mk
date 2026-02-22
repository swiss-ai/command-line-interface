.PHONY: install test-installation

install:
	uv pip install git+https://github.com/OpenInterpreter/open-interpreter.git

test-installation:
	interpreter --version
