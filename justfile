set windows-shell := ["cmd.exe", "/d", "/c"]

lua_paths := "init.lua lua luasnippets tests scripts/tests"
minimal_init := "scripts/tests/minimal.vim"

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

validate-test-suites:
    nvim --headless --clean -l scripts/tests/validate.lua tests/core tests/integration

# Alias of test-core
test: test-core

# Run one core or integration spec
test-spec spec:
    nvim --headless --noplugin -u {{ minimal_init }} -c "lua require('plenary.busted').run([[{{ spec }}]])" -c "qall"

# Run hermetic core specs
test-core: validate-test-suites
    nvim --headless --noplugin -u {{ minimal_init }} -c "PlenaryBustedDirectory tests/core/ {minimal_init = '{{ minimal_init }}'}"

# Run parser, snippet, and executable integration specs
test-integration: validate-test-suites
    nvim --headless --noplugin -u {{ minimal_init }} -c "PlenaryBustedDirectory tests/integration/ {minimal_init = '{{ minimal_init }}'}"

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
