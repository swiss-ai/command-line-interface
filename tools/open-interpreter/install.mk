.PHONY: install test-installation

install:
	pip install git+https://github.com/OpenInterpreter/open-interpreter.git

test-installation:
	interpreter --version
