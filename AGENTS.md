# AGENTS Instructions

## Project Overview

OrbitVim is a modular Neovim configuration written in Lua. It bootstraps
`lazy.nvim`, loads plugin specs from `lua/plugins/`, applies Nv UI/base46
configuration, and provides a custom Tool Manager for LSP, DAP, formatter,
linter, parser, and package management.

The main technologies are Neovim's Lua APIs, `lazy.nvim`, Nv UI/base46, Mason,
`nvim-lspconfig`, `conform.nvim`, `nvim-lint`, `nvim-dap`, Plenary/Busted,
Stylua, and Luacheck.

## Architecture and Ownership

| Area | Owner |
| --- | --- |
| Bootstrap | `init.lua` bootstraps `lazy.nvim`, imports `lua/plugins/`, and calls `require("config.starter").setup()` |
| Startup | `lua/config/starter.lua` orchestrates startup after Lazy setup |
| Editor defaults | `lua/config/defaults.lua` sets baseline defaults and prepends Mason `bin` to `PATH` |
| User-facing behavior | `lua/config/options.lua`, `keymaps.lua`, `autocmds.lua`, `events.lua`, and `filetypes.lua` |
| UI and theme | `lua/chadrc.lua` owns Nv UI/base46 overrides; `lua/config/theme.lua` loads generated highlight caches |
| Tool registry | `lua/config/tools.lua` is canonical; `lua/config/packages.lua` derives Mason packages, LSP servers, and Treesitter parsers |
| Formatting and linting | `lua/config/formatter/` and `lua/config/linter/` |
| Plugins | `lua/plugins/`, grouped by feature; LSP and DAP setup live in their respective subdirectories |
| Tool Manager | `lua/tool/` owns state, actions, rendering, Mason integration, errors, and formatter/linter ordering |
| Shared helpers | `lua/utils/`; reuse an existing domain module before adding another |
| Commands | `lua/cmds/`, loaded during startup |
| Core tests | `lua/test/spec/`, using hermetic Plenary tests |
| Integration tests | `lua/test/integration/`, for installed plugins, parsers, and executables |
| Test support | `lua/test/helpers.lua`, `lua/test/install_parsers.lua`, and `scripts/tests/minimal.vim` |

## Development Rules

- Add plugin specs to the closest feature file under `lua/plugins/`.
- Keep language-tool definitions in `lua/config/tools.lua`. Do not duplicate
  Mason package lists unless a package is intentionally an extra dependency in
  `lua/config/packages.lua`.
- Put formatter and linter behavior in their owning `lua/config/` subdirectory.
- Keep `lua/config/` modules declarative. Move calculations, event registration,
  runtime mutation, and plugin setup glue to the owning utility, plugin setup,
  or domain module.
- For Tool Manager changes, update `lua/tool/` and protect qualifying behavior
  with focused core tests.
- Before changing startup behavior, inspect `init.lua` and
  `lua/config/starter.lua` to confirm load order.
- Keep `lazy-lock.json` unchanged unless the task intentionally updates plugin
  versions.

## Commands

Install `stylua`, `luacheck`, Tree-sitter CLI 0.26.1 or newer, and Neovim before
running development commands. Open Neovim once to bootstrap plugins; the test
bootstrap expects `plenary.nvim` in Neovim's Lazy data directory. Install
configured parsers with `:TSInstallAll` when integration tests need them.

| Command | Purpose |
| --- | --- |
| `make fmt` | Rewrite Lua formatting |
| `make fmt-check` | Check formatting without modifying files |
| `make lint` | Run Luacheck |
| `make test` / `make test-core` | Run hermetic core specs |
| `make test-integration` | Run plugin, parser, and executable integration specs |
| `make test-all` | Run both test suites |
| `make all` | Run the read-only core validation: format check, lint, and core specs |
| `nvim --headless "+qall"` | Smoke-test startup |

Run a single spec with:

```bash
nvim --headless --noplugin -u scripts/tests/minimal.vim \
  -c "PlenaryBustedFile lua/test/spec/tool_state_spec.lua {minimal_init = 'scripts/tests/minimal.vim'}"
```

## Testing Policy

Production changes do not automatically require a new test. Add or update one
only when it protects at least one of these contracts:

- a reproduced regression that fails before the fix
- persistence, safety, ordering, or a state transition
- a documented cross-module invariant
- a seam with Neovim, a plugin, parser, or executable whose contract can drift
- branch-heavy headless behavior not already covered by a deeper interface test

Core tests must be deterministic and hermetic. Integration tests are required
for changes to Treesitter queries or parsers, LuaSnip collections, SQLFluff
executable behavior, or their adapters. Missing integration dependencies must
fail the suite; pending and silently skipped tests are not allowed.

### Test Design

- Test observable behavior at the module interface: outputs, side effects,
  errors, state transitions, and cross-module invariants.
- Identify a plausible behavior-breaking mutation before accepting a test. For
  regressions, run the test red before the fix when practical.
- Prefer one table-driven invariant over separate tests for individual fields,
  tools, icons, or filetypes.
- Do not test only that a module, table, function, or primitive type exists when
  a behavioral assertion already exercises it.
- For declarative configuration, protect required schema, ordering, derivation,
  safety policy, and consumer-facing contracts. Avoid pinning cosmetic values.
- Mock external dependencies at the owning module's seam. Avoid private-state
  assertions and production-only test interfaces.
- Replace shallow tests when a deeper interface test supersedes them; do not
  layer both.
- Data-only changes need tests only when they alter validated schema,
  derivation, ordering, or user-visible behavior.
- Prefer extending an existing domain contract over creating another spec.
  More than three cases or roughly 80 lines for one change requires an
  explanation of why a table-driven or deeper test is insufficient.
- Never change expected values only to make a test pass. State whether the
  contract changed, the old test was wrong, or production regressed.
- Characterization and compatibility tests must name the behavior they preserve
  and should be removed when the old interface or migration path disappears.

### Isolation

- Core tests must not use the network, install Mason packages, update plugins,
  or depend on external executables.
- Restore modified buffers, windows, globals, options, and `package.loaded`
  entries.
- Redirect files, logs, and persisted state below
  `vim.g.orbitvim_test_root`; never write to real Neovim user state.

## Code Style

- Follow `.stylua.toml`: two-space indentation, Unix line endings, and automatic
  quote preference.
- Follow `.editorconfig`: UTF-8, final newline, and no trailing whitespace.
- Keep modules small and aligned with existing feature areas.
- Prefer structured Lua tables, Neovim APIs, and existing `lua/utils/` helpers
  over ad hoc strings or new helper modules.
- Use comments only for non-obvious behavior and avoid broad rewrites when a
  focused change is sufficient.

## Tool Registry Rules

- Runtime tool entries should include the Mason package when Mason manages them
  and list their supported filetypes.
- Parser entries map Treesitter parser names to Neovim filetypes; package entries
  describe non-toggleable installer dependencies.
- DAP entries may use `mason = nil` for external adapters such as virtualenv
  `debugpy`.
- Ordered defaults belong in `formatter_defaults` and `linter_defaults`.
- Package, LSP, and parser derivation must remain deterministic and sorted.
- Persisted Tool Manager state must tolerate missing, invalid, and stale
  `tools.json` data.

## Safety

- Do not commit secrets, tokens, machine-specific paths, or generated
  credentials.
- Treat `lua/config/*/template/` as reusable templates; do not embed private
  values.
- Preserve the Windows `ClearShada` safeguard that skips `main.shada`.
- Do not perform destructive filesystem operations without resolving and
  verifying their exact target.

## Completion Checklist

- Run `make all`.
- Run `make test-integration` when an external integration changed.
- Run `nvim --headless "+qall"` when a startup path changed.
- Keep documentation synchronized with commands, ownership, and layout.
- In the final report, state `Tests added`, `Tests updated`, or `No tests added`
  and name the protected regression or contract.
