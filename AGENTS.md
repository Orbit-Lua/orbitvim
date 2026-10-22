# AGENTS Instructions

## Git

- Write commits in [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) format.
- Author commits as the user alone, with no `Co-Authored-By` or other co-author trailers.
- Commit as the plan progresses. Before pushing, squash related commits into one to keep history clean.
- Push only after the user approves that push.
- Version releases with [Semantic Versioning 2.0.0](https://semver.org/).
- Keep `lazy-lock.json` unchanged unless plugin versions are in scope.
- Archive a removed feature with an annotated `archive/<name>` tag on the last commit that contains it, not with a branch.

## Contracts

`init.lua` runs three phases in order: editor setup, Lazy bootstrap and spec import, then commands and final UI setup. Preserve user-visible commands, mappings and persisted state unless the task changes them.

Tool Manager's UI interface is `require("tool").open()` / `.close()`. Its operation interface, `tool.manager`, takes logical selections, never cursor positions, Nui objects or render callbacks. Read [architecture](doc/architecture.md) before moving these boundaries and the [Tool Manager guide](doc/tool-manager.md) before changing its workflows.

Read the [settings guide](doc/settings.md) before changing schema defaults, merge rules, reload scope or settings/state precedence. `settings.schema.json` owns public defaults. `settings.json` is personal and ignored by Git. Tool enablement and saved order stay in the data directory's `tools.json`.

## Ownership

| Change | Owner |
| --- | --- |
| Editor options, PATH, autocmds, filetypes, general keys, theme activation | `lua/core/` |
| Lazy plugin identity, dependencies, triggers, plugin keys, lifecycle callbacks | `lua/plugins/` |
| Editable plugin and language options | `lua/config/` |
| Settings schema, decoding, validation | `settings.schema.json`, `lua/config/settings.lua` |
| Settings application, rollback, save observation | `lua/core/settings.lua` |
| Tool IDs, runtime aliases, filetypes, Mason packages, default priority | `lua/config/tools.lua` |
| Derived package, LSP server and parser lists | `lua/config/packages.lua` |
| Tool Manager options, mapping/help text, install policy | `lua/config/tool_manager.lua` |
| LSP, DAP, completion, formatting, linting, snippets, Tree-sitter activation | `lua/runtime/` |
| User commands | `lua/commands/` |
| Tool operations, persistence, ordering, Mason seam, category adapters | `lua/tool/` |
| Nui view sessions, rendering, details | `lua/tool/ui/` |
| Shared helpers with concrete local interfaces | `lua/utils/` |
| Nv UI/base46 entry point | `lua/chadrc.lua` |
| Test bootstrap and fixtures | `tests/helpers.lua`, `scripts/tests/` |

- Importing a plugin spec must not register commands, events or mappings, or load highlight caches. Lazy lifecycle callbacks call the feature owner.
- Import owners directly. Do not add forwarding facades or depend on Lazy/Mason internals. Add a module only when its interface hides meaningful complexity.
- Treat `lua/config/*/template/` as reusable templates.

## Tool registry and state

- Keep tool definitions canonical. Use `runtime_name` when a backend identifier differs from the persisted logical ID and translate at the runtime boundary.
- Supported filetypes and initial activation are distinct: do not activate every supported tool where a runtime list or condition is intentional.
- Ordered defaults belong in `formatter_defaults` and `linter_defaults`. Keep derived lists sorted and unique.
- Parsers map parser names to Neovim filetypes. Packages are non-toggleable dependencies. External tools set `mason = nil`.
- Tool Manager must accept missing, malformed and stale `tools.json` and legacy `service.json`, keep logical keys and valid saved values, persist the complete formatter/linter order including disabled tools, and retain unrelated runtime entries.
- Parser and package actions cannot toggle or reorder. Automatic installation enables a tool only after success; failed or manual installation leaves enablement unchanged.
- A view session owns its subscriptions, timers, selection, help and details, and disposes them on normal close, external close and buffer deletion. An installation may finish after close but must not redraw a closed or later session. Keep help visible through refresh and preserve selection by logical identity, not line number.

## Platforms

Linux and Windows are equal targets: the same recipes, complete suites, native build checks and startup checks run on both.

- Code under `lua/` detects the platform through `utils.os`; standalone scripts and test bootstraps may not load it. Name platform-specific executables explicitly (`.cmd`, `.exe`, `Scripts/` versus `bin/`) and build paths with `/`, which Neovim accepts on Windows. Values handed to the operating system, such as `PATH` entries, use the native separator.
- Start external programs from argument lists, never shell strings: Windows users may select PowerShell. Only terminals use the interactive shell.
- The `justfile` runs recipes with `sh` on Linux and native `cmd.exe` on Windows, so batch launchers work without changing PowerShell execution policy. Recipe bodies must use quoting both shells accept: double quotes outside, single quotes inside.
- Every CI step that validates behaviour calls a `just` recipe. CI platform branches only install dependencies and set up the filesystem.
- Windows builds use MSYS2's UCRT64 GCC and Make with the runner's native Git. Do not add an MSYS Git to PATH. Running Neovim through MSYS Make can drop `LOCALAPPDATA` and hang Plenary on E492.
- Keep the Windows `ClearShada` rule that skips `main.shada`. Resolve exact targets before destructive filesystem operations.

## Tests

- A test enters the repo only when it guards behaviour no existing test covers and fails when that behaviour breaks. Weigh this before adding each one.
- Run throwaway tests freely to check your work; keep them out of the repo unless they pass that bar.
- Qualifying behaviour: a reproduced regression, persistence or safety, ordering or state transitions, cross-module invariants, external seams, or branch-heavy logic not covered more deeply. Name the contract and a mutation that would break it in your report.
- Do not add tests whose only evidence is constant values, export existence, label/icon inventories, source substrings, expected values recomputed by the implementation, cosmetic snapshots, fixed counts, option tables, or mocks that mirror the implementation's branches. Do not restore removed helper specs (`buf_hl`, `get_file_icons`, `make_relative_path`, `rstrip_slash`, window offsets, OS/date wrappers).
- Execute parser queries, snippet expansions and executable adapters instead of inspecting them. Registry schema references, cross-module derivation, persisted JSON and external templates are valid outputs.
- Never change an expected value just to pass: state whether the contract changed, the test was wrong, or production regressed. Explain in the report and commit message any single change that needs more than three cases or about 80 lines of test.
- Core specs are hermetic: no network, Mason installs, plugin updates or external executables. Mock at the owning seam; use the installed Nui without mocking its window API. Restore buffers, windows, globals, options, mappings, runtimepath, timers and `package.loaded`/`package.preload` entries even after a failed assertion. Write fixtures and state only below `vim.g.orbitvim_test_root` via `tests.helpers`.
- Integration specs fail when a dependency is missing; pending or skipped tests are rejected by `scripts/tests/validate.lua`.
- `tests/integration/treesitter_tsql_corpus_spec.lua` executes every `sql` fence in `doc/tsql-conventions.md`; a fence edit there changes test input.
- End each report with `Tests added`, `Tests updated` or `No tests added` and the contract protected.

## Validation

Prepare Neovim 0.12+, `just`, StyLua, Luacheck and Tree-sitter CLI 0.26.1+. Open Neovim once so Lazy installs Plenary and Nui; core specs load them from Lazy's data directory. Integration specs also need `:TSInstallAll`, LuaSnip, Markdown preview, SQLFluff, and `json-lsp` from Mason or `vscode-json-language-server` on PATH. Build checks need Git, GNU Make, GCC or Clang, and Bash; Windows also needs Windows PowerShell and accepts LuaRocks' Luacheck batch launcher or the standalone executable.

`just --list` names the recipes; `just test-spec tests/core/tool_state_spec.lua` runs one spec. CI calls `just deps` and `just parsers` before the suites.

- Run `just all` before finishing.
- Add `just test-integration` for Tree-sitter queries, parsers, LuaSnip collections, SQLFluff, JSON schema language-server behaviour, or their adapters.
- Add `just test-build` for LuaSnip or Markdown preview build changes, and `just smoke` for startup or plugin-loading changes.
- Report the checks run and any missing dependency.

## Docs

- Keep this file, `README.md` and every other doc concise and plain: each sentence carries information, with no filler.
- `README.md` is for users: install, usage, configuration and platform notes. Contributor workflow belongs here.
- Update `doc/tool-manager.md` for Tool Manager behaviour, `doc/architecture.md` for boundaries, `doc/settings.md` for settings, and the owning `doc/tsql-*.md` for SQL changes.
- Do not write counts, test totals or change history into docs; they drift. Git history records past audits.
- Follow `.stylua.toml` and `.editorconfig`; comment only non-obvious behaviour. Never commit secrets, tokens, credentials or private machine paths.
