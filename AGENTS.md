<!-- markdownlint-disable MD013 -->

# AGENTS Instructions

## Project

OrbitVim is a Lua Neovim configuration. `init.lua` runs editor setup, imports Lazy plugin specifications, then registers commands and finishes UI setup. Tool Manager manages LSP, DAP, formatter, linter, parser, and package state.

Read `init.lua` before changing startup or plugin loading. Preserve its phase order and the user-visible commands, mappings, and persisted state unless the task explicitly changes them.

## Where changes belong

| Change | Owner |
| --- | --- |
| Startup order | `init.lua` |
| Editor options, PATH, autocmds, filetypes, general keys, theme activation | `lua/core/` |
| Lazy plugin identity, dependencies, loading triggers, keys | `lua/plugins/` |
| Plugin options and language settings | `lua/config/` |
| Canonical language-tool registry | `lua/config/tools.lua` |
| Derived package, LSP server, and parser lists | `lua/config/packages.lua` |
| LSP, DAP, completion, formatting, linting, and snippet setup | `lua/runtime/` |
| User command registration | `lua/commands/` |
| Tool Manager state, actions, Mason and category adapters | `lua/tool/` |
| Tool Manager rendering, layout, help, cursor, and live updates | `lua/tool/ui/` |
| AI endpoint persistence and statusline integration | `lua/ai/` |
| Shared helpers | `lua/utils/` |
| Nv UI/base46 entry point | `lua/chadrc.lua` |
| Core specs and external integration specs | `lua/test/spec/` and `lua/test/integration/` |

Keep `lua/plugins/` limited to `LazySpec[]` definitions and their Lazy lifecycle callbacks. Importing a spec must not register commands, events, mappings, or load highlight caches. Put editable values in `lua/config/` and runtime mutation in the owning `lua/runtime/` or `lua/core/` module. Prefer a direct import over a forwarding facade; add a module only when it gives callers a meaningful interface.

Keep language-tool definitions in `lua/config/tools.lua`. Do not duplicate Mason package lists unless a package is an intentional extra dependency. Preserve sorted, deterministic derivation of package, server, and parser lists. Ordered defaults belong in `formatter_defaults` and `linter_defaults`. Parser entries map Tree-sitter parser names to Neovim filetypes; package entries describe non-toggleable dependencies. Managed runtime tools should declare their Mason package and supported filetypes; external DAP adapters may have `mason = nil`.

Keep Tool Manager persistence compatible with missing, invalid, and stale `tools.json`; it also reads legacy `service.json`. For changes to toggling, installation, ordering, window lifecycle, or persisted state, protect the affected behavior through the public module interface.

Keep `lazy-lock.json` unchanged unless the task intentionally changes plugin versions. Update README for user workflows and `doc/` for owning SQL behavior; update this file when ownership or validation rules change.

## Validation

From the repository root, install Neovim 0.12+, StyLua, Luacheck, Tree-sitter CLI 0.26.1+, and `make`. Open Neovim once to bootstrap plugins; core tests expect `plenary.nvim` in Lazy's data directory. Install configured parsers with `:TSInstallAll` before integration tests that need them.

| Command | Effect |
| --- | --- |
| `make fmt` | Rewrite Lua formatting, including `init.lua` |
| `make fmt-check` | Check formatting without rewriting |
| `make lint` | Run Luacheck |
| `make test` / `make test-core` | Run hermetic core specs |
| `make test-integration` | Run plugin, parser, and executable integration specs |
| `make test-all` | Run both suites |
| `make all` | Format check, lint, and core specs |
| `nvim --headless "+qall"` | Smoke-test startup; may use installed plugins and user state |

For one core spec:

```sh
nvim --headless --noplugin -u scripts/tests/minimal.vim \
  -c "lua require('plenary.busted').run('lua/test/spec/tool_state_spec.lua')" \
  -c 'qall'
```

Run `make all` before completion. Run `make test-integration` for changes to Tree-sitter queries or parsers, LuaSnip collections, SQLFluff executable behavior, or their adapters. Run the startup smoke test when startup changes. Report the checks actually run; do not silently skip missing integration dependencies.

## Tests

Add or update a test only when it protects a reproduced regression, persistence or safety behavior, ordering or state transitions, a cross-module invariant, an external seam, or branch-heavy headless behavior not already covered more deeply. Moving a file or adding a constant alone does not justify a test.

Test observable outputs, side effects, errors, and state transitions at the module interface. Identify a plausible behavior-breaking mutation. Prefer a table-driven invariant over separate tests for each field, icon, tool, or filetype. Replace shallow wiring or compatibility tests when a deeper behavior test supersedes them; do not layer both. Avoid assertions that only show a function, table, or primitive type exists. Do not change expected values merely to make a failure pass; state whether the contract changed, the old test was wrong, or production regressed. For more than three cases or roughly 80 lines for one change, explain why a deeper or table-driven test is insufficient.

Core specs must be deterministic and hermetic: no network, Mason installation, plugin updates, or external executables. Mock an external dependency at its owning seam. Restore buffers, windows, globals, options, and `package.loaded` entries. Write files, logs, and persisted state only below `vim.g.orbitvim_test_root`. Integration tests must fail when their required dependency is missing; pending or silently skipped tests are not acceptable.

## Safety and style

Follow `.stylua.toml` and `.editorconfig`. Keep changes aligned with existing feature owners and use comments for non-obvious behavior. Avoid broad rewrites that do not improve ownership, readability, or a tested contract.

Do not commit secrets, tokens, credentials, or private machine paths. Treat `lua/config/*/template/` as reusable templates. Preserve the Windows `ClearShada` rule that skips `main.shada`. Resolve and verify exact targets before destructive filesystem operations.

In the final report, state `Tests added`, `Tests updated`, or `No tests added` and name the behavior or contract protected.
