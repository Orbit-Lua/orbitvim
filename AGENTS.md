<!-- markdownlint-disable MD013 -->

# AGENTS Instructions

## Project and contracts

OrbitVim is a Lua Neovim configuration. Read `init.lua` before changing startup or plugin loading. Preserve its three phases: editor setup → Lazy bootstrap/spec import → commands and final UI setup. Preserve user-visible commands, mappings, and persisted state unless the task explicitly changes them.

Tool Manager manages LSP, DAP, linters, formatters, parsers, and dependency packages. Its public UI interface is `require("tool").open()` / `.close()`. The tool-operation interface is `tool.manager`; operations receive logical selections, never cursor positions, Nui objects, or render callbacks. Read [architecture](doc/architecture.md) before changing these boundaries and [Tool Manager behavior](doc/tool-manager.md) before changing its workflows.

## Ownership

| Change | Owner |
| --- | --- |
| Startup order | `init.lua` |
| Editor options, PATH, autocmds, filetypes, general keys, theme activation | `lua/core/` |
| Lazy plugin identity, dependencies, triggers, plugin keys and lifecycle callbacks | `lua/plugins/` |
| Editable plugin and language options | `lua/config/` |
| Canonical tool IDs, runtime aliases, filetypes, Mason packages, default priority | `lua/config/tools.lua` |
| Derived sorted package, LSP server, parser lists | `lua/config/packages.lua` |
| Tool Manager options, mapping/help descriptions and install policy | `lua/config/tool_manager.lua` |
| LSP, DAP, completion, formatting, linting, snippets and Tree-sitter activation | `lua/runtime/` |
| User command registration | `lua/commands/` |
| Tool operations, persistence, ordering, Mason seam, category adapters | `lua/tool/` |
| Nui view sessions, rendering, selected-tool details | `lua/tool/ui/` |
| AI endpoint persistence and statusline integration | `lua/ai/` |
| Shared helpers with concrete local interfaces | `lua/utils/` |
| Nv UI/base46 entry point | `lua/chadrc.lua` |
| Hermetic core and external integration specs | `tests/core/`, `tests/integration/` |
| Test fixtures/bootstrap/validation | `tests/helpers.lua`, `scripts/tests/` |

Importing a plugin spec must not register commands, events, mappings, or load highlight caches. Put editable values in config and runtime mutation in its feature owner; Lazy lifecycle callbacks may invoke that owner. Prefer direct imports. Do not add forwarding facades or proxy Lazy/Mason internal utilities. Add a module only when its interface hides meaningful complexity.

Keep tool definitions canonical. Use `runtime_name` when a backend identifier differs from the persisted logical ID; translate at the runtime boundary. Supported filetypes and initial activation are distinct: do not replace intentional runtime lists/conditions by activating every supported tool. Ordered defaults belong in `formatter_defaults` and `linter_defaults`. Preserve sorted, unique derivation of packages, servers and parsers. Parser definitions map parser names to Neovim filetypes; package definitions describe non-toggleable dependencies. Declare Mason packages and supported filetypes for managed runtime tools; external tools may have `mason = nil`.

Tool Manager must accept missing, malformed and stale `tools.json` and legacy `service.json`. Preserve logical state keys and valid saved values. Persist complete formatter/linter order including disabled tools, apply enabled tools to runtime, and retain unrelated runtime entries. Parser/package actions cannot toggle or reorder. Automatic installation enables only after success; failed/manual installation leaves enablement unchanged.

Nui owns Tool Manager windows, buffers, layout and text rendering. A view session owns subscriptions, timers, selection, help and details. Dispose resources on normal/external close and buffer deletion. An installation may complete after closing, but its callback must not redraw a closed or later session. Keep help visible through refresh, and preserve selection by logical identity rather than line number.

Keep `lazy-lock.json` unchanged unless plugin versions are intentionally in scope. Update README for user workflows, `doc/tool-manager.md` for Tool Manager behavior, `doc/architecture.md` for boundaries, and owning SQL documents for SQL changes. Update this file when ownership or validation rules change.

## Test admission

Add or update a test only to protect a reproduced regression, persistence/safety behavior, ordering/state transition, cross-module invariant, external seam, or branch-heavy behavior not already covered more deeply. Identify the observable contract and a plausible behavior-breaking mutation in the implementation report. File moves, renames and new constants alone require no tests.

Reject tests whose only evidence is:

- A constant value, export existence, primitive type, alias equality, or label/icon/file inventory.
- Source-code substrings or private wiring used as proof that runtime behavior works.
- An expected result computed by repeating the implementation under test.
- Cosmetic snapshots or fixed collection counts without a user-visible contract.
- Compatibility for unused APIs, or shallow cases already superseded by deeper coverage.

The audit removed the old Tool Manager cursor/table/renderer/help/layout wiring specs; public Nui interaction and lifecycle coverage replaces them. Do not restore helper tests for removed APIs (`buf_hl`, `get_file_icons`, `make_relative_path`, `rstrip_slash`, window offsets, or unused OS environment/date wrappers). Exact snippet counts/trigger inventories, README/source substring assertions, formatter constant inventories, Noice icon/format tokens, ambient clock/platform checks, and Tab callback existence checks were removed or replaced with behavior tests. Do not add them back merely to accompany an implementation change.

Registry schema/default references and deterministic cross-module derivation are valid invariants. Persisted JSON and external configuration/templates are valid outputs/seams; inspecting them is not a source-wiring test. Execute parser queries, snippet expansions and executable adapters to verify their behavior. Do not remove safety/behavior coverage because an assertion happens to be simple.

Test outputs, errors, side effects and transitions through the owning interface. Prefer table-driven invariants. Replace superseded cases rather than layering both. Do not change expected values just to pass: state whether the contract changed, the old test was wrong, or production regressed. For more than three cases or roughly 80 lines for one change, explain why a smaller/deeper or table-driven test cannot cover the independent branches. Test count and coverage growth are not goals.

Core specs must be deterministic and hermetic: no network, Mason installation, plugin updates or external executables. Mock dependencies at the owning seam. Public UI specs use installed Nui; they must not mock its window API to assert our own calls. Restore buffers/windows, current context, globals/options/mappings, runtimepath, timers and changed `package.loaded`/`package.preload` entries, including after assertion failure. Write fixtures, logs and state only below `vim.g.orbitvim_test_root`; use `tests.helpers`. Restore previous values, not assumed defaults. Integration tests must fail when a required dependency is missing; pending/skipped tests are prohibited.

## Validation

From the repository root, prepare Neovim 0.12+, StyLua, Luacheck, Tree-sitter CLI 0.26.1+ and `make`. Open Neovim once to bootstrap plugins: core specs require Plenary and Nui in Lazy's data directory. Install configured parsers with `:TSInstallAll` before parser integration checks. Integration tests also require LuaSnip and SQLFluff.

| Command | Effect |
| --- | --- |
| `make fmt` | Rewrite Lua formatting, including tests and `init.lua` |
| `make fmt-check` | Check formatting without rewriting |
| `make lint` | Run Luacheck |
| `make test` / `make test-core` | Run hermetic core specs |
| `make test-integration` | Run parser, snippet and executable integration specs |
| `make test-all` | Run both suites |
| `make all` | Format check, lint and core specs |
| `nvim --headless "+qall"` | Smoke-test startup with installed plugins/user state |

For one core spec:

```sh
nvim --headless --noplugin -u scripts/tests/minimal.vim \
  -c "lua require('plenary.busted').run('tests/core/tool_state_spec.lua')" \
  -c 'qall'
```

Run `make all` before completion. Run `make test-integration` for changes to Tree-sitter queries/parsers/runtime, LuaSnip collections, SQLFluff executable behavior, or their adapters. Run startup smoke checks when startup/plugin loading changes. Report checks actually run and missing dependencies; do not silently skip them.

## Safety and style

Follow `.stylua.toml` and `.editorconfig`; use comments for non-obvious behavior. Avoid broad rewrites without an ownership, readability or contract benefit.

Do not commit secrets, tokens, credentials or private machine paths. Treat `lua/config/*/template/` as reusable templates. Preserve the Windows `ClearShada` rule that skips `main.shada`. Resolve exact targets before destructive filesystem operations.

In the final report, state `Tests added`, `Tests updated`, or `No tests added` and name the behavior or contract protected.
