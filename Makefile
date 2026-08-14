ifeq ($(OS),Windows_NT)
    LUACHECK := luacheck.bat
else
    LUACHECK := luacheck
endif

.PHONY: all fmt fmt-check lint test test-core test-integration test-all validate-test-suites

all: fmt-check lint test-core

fmt:
	echo "===> Formatting"
	stylua lua/ luasnippets/ --config-path=.stylua.toml

fmt-check:
	echo "===> Checking formatting"
	stylua --check lua/ luasnippets/ --config-path=.stylua.toml

lint:
	echo "===> Linting"
	$(LUACHECK) lua luasnippets --globals vim

validate-test-suites:
	echo "===> Validating test suites"
	nvim --headless --clean --cmd "set rtp^=." \
		-c "lua require('test.validate_suite').check('lua/test/spec')" \
		-c "lua require('test.validate_suite').check('lua/test/integration')" \
		-c "qall"

test: test-core

test-core: validate-test-suites
	echo "===> Testing core behavior"
	nvim --headless --noplugin -u scripts/tests/minimal.vim \
		-c "PlenaryBustedDirectory lua/test/spec/ {minimal_init = 'scripts/tests/minimal.vim'}"

test-integration: validate-test-suites
	echo "===> Testing external integrations"
	nvim --headless --noplugin -u scripts/tests/minimal.vim \
		-c "PlenaryBustedDirectory lua/test/integration/ {minimal_init = 'scripts/tests/minimal.vim'}"

test-all: test-core test-integration
