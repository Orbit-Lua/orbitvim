# AGENTS Instructions

## Git

- Write commits in [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) format.
- Author commits as the user alone, with no `Co-Authored-By` or other co-author trailers.
- Commit as the plan progresses. Before pushing, squash related commits into one to keep history clean.
- Push only after the user approves that push.
- Version releases with [Semantic Versioning 2.0.0](https://semver.org/).
- Keep `lazy-lock.json` unchanged unless plugin versions are in scope.
- Archive removed features with an annotated `archive/<name>` tag on the last commit that contains them, not with a branch.

## Contracts

OrbitVim is a Lua Neovim configuration. `init.lua` runs three phases in order: editor setup, Lazy bootstrap and spec import, then commands and final UI setup. Preserve user-visible commands, mappings and persisted state unless the task changes them.

Tool Manager's UI interface is `require("tool").open()` / `.close()`; its operation interface is `tool.manager`, which takes logical selections, never cursor positions, Nui objects or render callbacks. Read [architecture](doc/architecture.md) before changing these boundaries and the [Tool Manager guide](doc/tool-manager.md) before changing its workflows.

Read the [settings guide](doc/settings.md) before changing schema defaults, merge rules, reload scope or settings/state precedence. `settings.schema.json` owns public defaults; `settings.json` is personal and ignored by Git. Tool enablement and saved order remain in the data directory's `tools.json`.

## Ownership

| Change | Owner |
| --- | --- |
| Startup order | `init.lua` |
| Editor options, PATH, autocmds, filetypes, general keys, theme activation | `lua/core/` |
| Lazy plugin identity, dependencies, triggers, plugin keys, lifecycle callbacks | `lua/plugins/` |
| Editable plugin and language options | `lua/config/` |
| Public settings schema, decoding, validation and accepted data | `settings.schema.json`, `lua/config/settings.lua` |
| Settings application, rollback and save observation | `lua/core/settings.lua` |
| Canonical tool IDs, runtime aliases, filetypes, Mason packages, default priority | `lua/config/tools.lua` |
| Derived sorted package, LSP server and parser lists | `lua/config/packages.lua` |
| Tool Manager options, mapping/help descriptions, install policy | `lua/config/tool_manager.lua` |
| LSP, DAP, completion, formatting, linting, snippets, Tree-sitter activation | `lua/runtime/` |
| User command registration | `lua/commands/` |
| Tool operations, persistence, ordering, Mason seam, category adapters | `lua/tool/` |
| Nui view sessions, rendering, selected-tool details | `lua/tool/ui/` |
| Shared helpers with concrete local interfaces | `lua/utils/` |
| Nv UI/base46 entry point | `lua/chadrc.lua` |
| Hermetic core and external integration specs | `tests/core/`, `tests/integration/` |
| Test fixtures, bootstrap, suite validation | `tests/helpers.lua`, `scripts/tests/` |

- Importing a plugin spec must not register commands, events or mappings, or load highlight caches. Editable values go in config, runtime mutation in the feature owner; Lazy lifecycle callbacks may call that owner.
- Import owners directly. Do not add forwarding facades or proxy Lazy/Mason internals. Add a module only when its interface hides meaningful complexity.

## Tool registry and state

- Keep tool definitions canonical. Use `runtime_name` when a backend identifier differs from the persisted logical ID and translate at the runtime boundary.
- Supported filetypes and initial activation are distinct: do not replace intentional runtime lists or conditions by activating every supported tool.
- Ordered defaults belong in `formatter_defaults` and `linter_defaults`. Keep derived package, server and parser lists sorted and unique.
- Parser definitions map parser names to Neovim filetypes; package definitions describe non-toggleable dependencies. Managed runtime tools declare Mason packages and filetypes; external tools may set `mason = nil`.
- Tool Manager must accept missing, malformed and stale `tools.json` and legacy `service.json`, keep logical keys and valid saved values, persist the complete formatter/linter order including disabled tools, and retain unrelated runtime entries.
- Parser and package actions cannot toggle or reorder. Automatic installation enables a tool only after success; failed or manual installation leaves enablement unchanged.
- A view session owns its subscriptions, timers, selection, help and details, and disposes them on normal close, external close and buffer deletion. An installation may finish after close but must not redraw a closed or later session. Keep help visible through refresh and preserve selection by logical identity, not line number.

## Tests

- A test enters the repo only when it guards behaviour no existing test covers and fails when that behaviour breaks. Weigh this before adding each one.
- Run throwaway tests freely to check your work; keep them out of the repo unless they pass that bar.
- Qualifying behaviour here: a reproduced regression, persistence or safety, ordering or state transitions, cross-module invariants, external seams, or branch-heavy logic not covered more deeply. Name the contract and a mutation that would break it in your report.
- Do not add tests whose only evidence is constant values, export existence, label/icon inventories, source substrings, expected values recomputed by the implementation, cosmetic snapshots, fixed counts, option tables, or mocks that mirror the implementation's own branches. Do not restore removed helper specs (`buf_hl`, `get_file_icons`, `make_relative_path`, `rstrip_slash`, window offsets, OS/date wrappers).
- Registry schema references, deterministic cross-module derivation, persisted JSON and external templates are valid outputs. Execute parser queries, snippet expansions and executable adapters instead of inspecting them.
- Never change an expected value just to pass: state whether the contract changed, the test was wrong, or production regressed. Explain any single change that needs more than three cases or about 80 lines of test.
- Core specs are hermetic: no network, Mason installs, plugin updates or external executables. Mock at the owning seam; use the installed Nui without mocking its window API. Restore buffers, windows, globals, options, mappings, runtimepath, timers and `package.loaded`/`package.preload` entries even after a failed assertion. Write fixtures and state only below `vim.g.orbitvim_test_root` via `tests.helpers`.
- Integration specs must fail when a dependency is missing; pending or skipped tests are prohibited.
- End each report with `Tests added`, `Tests updated` or `No tests added` and the contract protected.

## Validation

Support Linux and Windows with the same validation recipes, complete test suites, native build checks and startup checks. Keep CI platform branches limited to dependency installation and filesystem setup.

Prepare Neovim 0.12+, `just`, StyLua, Luacheck and Tree-sitter CLI 0.26.1+. Open Neovim once so Lazy installs Plenary and Nui, which core specs load from Lazy's data directory. Integration specs also need `:TSInstallAll`, LuaSnip, Markdown preview, SQLFluff and `json-lsp` (Mason) or `vscode-json-language-server` on PATH. Build integration requires Git, GNU Make, a C compiler (GCC or Clang), and Bash; Windows also needs Windows PowerShell. Windows accepts LuaRocks' Luacheck batch launcher or the official standalone executable.

| Command | Effect |
| --- | --- |
| `just fmt` / `just fmt-check` | Rewrite / check StyLua formatting |
| `just lint` | Luacheck |
| `just test-core` | Hermetic core specs |
| `just test-integration` | Parser, snippet and executable integration specs |
| `just test-build` | Build and execute locked LuaSnip and Markdown preview dependencies |
| `just all` | `fmt-check`, `lint`, `test-core` |
| `just smoke` | Execute startup and propagate Lua errors |
| `nvim --headless "+qall"` | Startup smoke test with installed plugins and user state |

One core spec:

```sh
nvim --headless --noplugin -u scripts/tests/minimal.vim \
  -c "lua require('plenary.busted').run('tests/core/tool_state_spec.lua')" \
  -c 'qall'
```

- Run `just all` before finishing. Add `just test-integration` for Tree-sitter queries, parsers or runtime, LuaSnip collections, SQLFluff behaviour, JSON schema language-server behaviour, or their adapters, and the smoke test for startup or plugin-loading changes. Report the checks run and any missing dependency.
- The `justfile` uses `sh` on Linux and native `cmd.exe` on Windows; batch launchers work without changing PowerShell execution policy. Keep native Git on Windows when adding MSYS2 compiler and Make directories to PATH. Running Neovim through MSYS Make can drop `LOCALAPPDATA` and hang Plenary on E492.

## Docs

- Keep this file, `README.md` and every other doc concise and plain: each sentence carries information, with no filler.
- `README.md` covers user installation and usage; contributor workflow belongs here. Update `doc/tool-manager.md` for Tool Manager behaviour, `doc/architecture.md` for boundaries, and the owning `doc/tsql-*.md` for SQL changes.

## Safety

- Follow `.stylua.toml` and `.editorconfig`; comment only non-obvious behaviour.
- Never commit secrets, tokens, credentials or private machine paths.
- Treat `lua/config/*/template/` as reusable templates.
- Keep the Windows `ClearShada` rule that skips `main.shada`. Resolve exact targets before destructive filesystem operations.
