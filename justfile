set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

luacheck := if os_family() == "windows" { "luacheck.bat" } else { "luacheck" }
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
    {{ luacheck }} {{ lua_paths }} --globals vim

validate-test-suites:
    nvim --headless --clean --cmd "set rtp^=." -c "lua dofile('scripts/tests/validate.lua').check('tests/core')" -c "lua dofile('scripts/tests/validate.lua').check('tests/integration')" -c "qall"

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
