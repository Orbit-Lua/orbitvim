set windows-shell := ["cmd.exe", "/d", "/c"]

lua_paths := "init.lua lua luasnippets tests scripts/tests"

# Check formatting, lint, and run hermetic core specs
all: fmt-check lint test-core

# Rewrite Lua formatting
fmt:
    stylua {{ lua_paths }} --config-path=.stylua.toml

# Check formatting without rewriting
fmt-check:
    stylua --check {{ lua_paths }} --config-path=.stylua.toml

# Run Luacheck
lint:
    luacheck {{ lua_paths }}

# Alias of test-core
test: test-core

# Run one core or integration spec
test-spec spec:
    nvim --headless --clean -i NONE -l scripts/tests/run_suite.lua "{{ spec }}"

# Run hermetic core specs
test-core:
    nvim --headless --clean -i NONE -l scripts/tests/run_suite.lua tests/core

# Run parser, snippet, and executable integration specs
test-integration:
    nvim --headless --clean -i NONE -l scripts/tests/run_suite.lua tests/integration

# Run both suites
test-all: test-core test-integration

# Install the locked plugin revisions and fail if the lockfile changes
deps:
    nvim --headless -u NORC -l scripts/tests/restore_plugins.lua
    git diff --exit-code -- lazy-lock.json

# Install the parsers that integration specs execute
parsers:
    nvim --headless -u init.lua -l scripts/tests/install_parsers.lua

# Build and execute the locked native plugin dependencies
test-build:
    nvim --headless -u NONE -l scripts/tests/build_luasnip.lua
    nvim --headless -u NONE -l scripts/tests/build_markdown_preview.lua

# Execute startup with errors propagated to the caller
smoke:
    nvim --headless -u NORC -l scripts/tests/smoke.lua
