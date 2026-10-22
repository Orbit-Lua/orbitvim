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
    luacheck {{ lua_paths }} --globals vim

validate-test-suites:
    nvim --headless --clean -l scripts/tests/validate.lua tests/core tests/integration

# Alias of test-core
test: test-core

# Run hermetic core specs
test-core: validate-test-suites
    nvim --headless --noplugin -u {{ minimal_init }} -c "PlenaryBustedDirectory tests/core/ {minimal_init = '{{ minimal_init }}'}"

# Run parser, snippet, and executable integration specs
test-integration: validate-test-suites
    nvim --headless --noplugin -u {{ minimal_init }} -c "PlenaryBustedDirectory tests/integration/ {minimal_init = '{{ minimal_init }}'}"

# Run both suites
test-all: test-core test-integration

# Build and execute the locked native plugin dependencies
test-build:
    nvim --headless -u NONE -l scripts/tests/build_luasnip.lua
    nvim --headless -u NONE -l scripts/tests/build_markdown_preview.lua

# Execute startup with errors propagated to the caller
smoke:
    nvim --headless -u NORC -l scripts/tests/smoke.lua
