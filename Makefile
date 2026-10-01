ifeq ($(OS),Windows_NT)
    LUACHECK := luacheck.bat
else
    LUACHECK := luacheck
endif

.PHONY: all fmt fmt-check lint test test-core test-integration test-all validate-test-suites

all: fmt-check lint test-core

fmt:
	echo "===> Formatting"
	stylua init.lua lua/ luasnippets/ tests/ scripts/tests/ --config-path=.stylua.toml

fmt-check:
	echo "===> Checking formatting"
	stylua --check init.lua lua/ luasnippets/ tests/ scripts/tests/ --config-path=.stylua.toml

lint:
	echo "===> Linting"
	$(LUACHECK) init.lua lua luasnippets tests scripts/tests --globals vim

validate-test-suites:
	echo "===> Validating test suites"
	nvim --headless --clean --cmd "set rtp^=." \
		-c "lua dofile('scripts/tests/validate.lua').check('tests/core')" \
		-c "lua dofile('scripts/tests/validate.lua').check('tests/integration')" \
		-c "qall"

test: test-core

test-core: validate-test-suites
	echo "===> Testing core behavior"
	nvim --headless --noplugin -u scripts/tests/minimal.vim \
		-c "PlenaryBustedDirectory tests/core/ {minimal_init = 'scripts/tests/minimal.vim'}"

test-integration: validate-test-suites
	echo "===> Testing external integrations"
	nvim --headless --noplugin -u scripts/tests/minimal.vim \
		-c "PlenaryBustedDirectory tests/integration/ {minimal_init = 'scripts/tests/minimal.vim'}"

test-all: test-core test-integration
