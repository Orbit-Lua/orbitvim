# AGENTS Instructions

OrbitVim supports Linux and Windows. Preserve commands, mappings and persisted state unless the task changes their contracts.

## Git

- Write commits in [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) format.
- For a non-trivial change, write a commit body that explains why.
- Mark a breaking change with `!` and a `BREAKING CHANGE:` footer.
- Author commits as the user alone, without `Co-Authored-By` or other co-author trailers.
- Commit as the plan progresses.
- Before you push, squash related commits into one commit to keep the history clean.
- Push only after the user approves that push.
- Version releases with [Semantic Versioning 2.0.0](https://semver.org/).
- Keep `lazy-lock.json` unchanged unless plugin versions are in scope.
- To archive a removed feature, put an annotated `archive/<name>` tag on the last commit that contains it. Do not use a branch.

## Contracts

`init.lua` runs three phases in this order:

1. Editor setup.
2. Lazy bootstrap and spec import.
3. Commands and final UI setup.

Keep settings available also when the personal input is invalid.

Tool Manager's UI interface is `require("tool").open()` / `.close()`. Its operation interface is `tool.manager`. It takes logical selections, never cursor positions, Nui objects or render callbacks.

`settings.schema.json` owns the public defaults. `settings.json` is personal, and Git ignores it. Tool enablement and saved order stay in `tools.json` in the data directory.

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

- Importing a plugin spec must not register commands, events or mappings. It must not load highlight caches.
- Lazy lifecycle callbacks call the feature owner.
- Import owners directly. Do not add forwarding facades.
- Do not depend on Lazy or Mason internals.
- Add a module only when its interface hides meaningful complexity.
- Treat `lua/config/*/template/` as reusable templates.

## Tool registry and state

- Keep tool definitions canonical.
- When a backend identifier differs from the persisted logical ID, use `runtime_name`. Translate at the runtime boundary.
- Supported filetypes and initial activation are different things. Where a runtime list or condition is intentional, do not activate each supported tool.
- Put ordered defaults in `formatter_defaults` and `linter_defaults`.
- Keep derived lists sorted and unique.
- Parsers map parser names to Neovim filetypes.
- Packages are dependencies that users cannot toggle.
- External tools set `mason = nil`.
- Tool Manager must accept a missing, malformed or stale `tools.json` and a legacy `service.json`. When it reads them, it must:
  - Keep logical keys and valid saved values.
  - Persist the complete formatter and linter order, including disabled tools.
  - Keep unrelated runtime entries.
- Parser and package actions cannot toggle or reorder.
- Automatic installation enables a tool only after it succeeds. A failed or manual installation does not change enablement.
- A view session owns its subscriptions, timers, selection, help and details. It disposes them on normal close, external close and buffer deletion.
- An installation can finish after close. It must not redraw a closed session or a later session.
- Keep help visible through refresh.
- Keep the selection by logical identity, not by line number.

## Platforms

Linux and Windows are equal targets. The same recipes, complete suites, native build checks and startup checks run on both.

- Code under `lua/` detects the platform through `utils.os`. Standalone scripts and test bootstraps cannot load it.
- Name platform-specific executables explicitly: `.cmd`, `.exe`, `Scripts/` or `bin/`.
- Build paths with `/`. Neovim accepts it on Windows.
- Values for the operating system, such as `PATH` entries, use the native separator.
- Start external programs from argument lists, never from shell strings. Windows users can select PowerShell.
- Only terminals use the interactive shell.
- The `justfile` runs recipes with `sh` on Linux and with native `cmd.exe` on Windows. Thus batch launchers work without a change to the PowerShell execution policy.
- Recipe bodies must use quotes that both shells accept: double quotes outside, single quotes inside.
- Each CI step that validates behaviour calls a `just` recipe.
- Platform branches prepare dependencies and filesystem state. Both platforms run the complete suites.
- Windows builds use MSYS2's UCRT64 GCC and Make with the runner's native Git. Do not add an MSYS Git to PATH.
- Neovim that runs through MSYS Make can lose `LOCALAPPDATA`. Then Plenary hangs on E492.
- Keep the Windows `ClearShada` rule that skips `main.shada`.
- Resolve exact targets before destructive filesystem operations.

## Tests

- Add a test to the repo only when it guards behaviour that no existing test covers.
- The test must fail when that behaviour breaks. Weigh this before you add each test.
- Run throwaway tests freely to check your work.
- Keep throwaway tests out of the repo unless they meet the bar above.
- These behaviours qualify:
  - A reproduced regression.
  - Persistence or safety.
  - Ordering or state transitions.
  - Cross-module invariants.
  - External seams.
  - Branch-heavy logic that no deeper test covers.
- In your report, name the contract and a mutation that would break it.
- Reject a test when its only evidence is one of these:
  - Constant values, export existence or label/icon inventories.
  - Source substrings or expected values that the implementation recomputes.
  - Cosmetic snapshots, fixed counts or option tables.
  - Mocks that mirror the implementation's branches.
- Do not restore removed helper specs: `buf_hl`, `get_file_icons`, `make_relative_path`, `rstrip_slash`, window offsets and OS/date wrappers.
- Execute parser queries, snippet expansions and executable adapters. Do not only inspect them.
- Registry schema references, cross-module derivation, persisted JSON and external templates are valid outputs.
- Never change an expected value only to pass a test. State whether the contract changed, the test was wrong or production regressed.
- A single change can need more than three cases or about 80 lines of test. Explain it in the report and in the commit message.
- Core specs are hermetic: no network, Mason installs, plugin updates or external executables.
- Mock at the owning seam.
- Use the installed Nui, and do not mock its window API.
- Restore buffers, windows, globals, options, mappings, runtimepath, timers and `package.loaded`/`package.preload` entries, also after a failed assertion.
- Write fixtures and state only below `vim.g.orbitvim_test_root`, through `tests.helpers`.
- Integration specs fail when a dependency is missing. `scripts/tests/validate.lua` rejects pending or skipped tests.
- Keep snippet triggers unique and lowercase.
- Make placeholders useful.
- End complete statements with a semicolon, and put `$0` as the final cursor.
- When you change expansions, update the catalog.
- Protect transaction ownership, identifier validation and value parameterization, not trigger inventories.
- `tests/integration/treesitter_tsql_corpus_spec.lua` executes each `sql` fence in `doc/tsql-conventions.md`. A fence edit there changes test input.
- End each report with `Tests added`, `Tests updated` or `No tests added`, and the contract that it protects.

## Validation

Install Neovim 0.12+, `just`, StyLua, Luacheck and Tree-sitter CLI 0.26.1+. Open Neovim once, so that Lazy installs Plenary and Nui. Core specs load them from Lazy's data directory.

Integration specs also need these:

- `:TSInstallAll`, LuaSnip, Markdown preview and SQLFluff.
- `json-lsp` from Mason, or `vscode-json-language-server` on PATH.

Build checks need Git, GNU Make, GCC or Clang, and Bash. Windows also needs Windows PowerShell. It accepts the LuaRocks Luacheck batch launcher or the standalone executable.

`just --list` names the recipes. `just test-spec tests/core/tool_state_spec.lua` runs one spec. CI calls `just deps` and `just parsers` before the suites.

- Run `just all` before you finish.
- Also run `just test-integration` for changes to these: Tree-sitter queries, parsers, LuaSnip collections, SQLFluff, JSON schema language-server behaviour or their adapters.
- Also run `just test-build` for LuaSnip or Markdown preview build changes.
- Also run `just smoke` for startup or plugin-loading changes.
- Report the checks that you ran and each missing dependency.

## CI

- Keep a CI check only when it catches a concrete failure that no existing check covers.
- Identify that failure before you add or keep the check.
- Apply the test rules to CI checks too.
- Run the repo's entry points against real inputs or isolated fixtures.
- Reject duplicate checks, source-text assertions, copied inventories and checks that only prove that a command or file exists.
- Name each workflow, job and step by its target and its action.
- Propagate command failures.
- Count a missing prerequisite or skipped required coverage as a failure.
- After you change these rules, audit the repo against them.
- Validate changes locally. Then verify the required CI on the pushed commit.
- Report each uncovered contract and each unavailable check.

## Docs

- Keep each doc concise and plain. Each sentence must carry information.
- Write English docs to the [ASD-STE100](https://www.asd-ste100.org/) writing rules:
  - An instruction has 20 words or fewer. A description has 25 words or fewer.
  - Give one instruction in each sentence.
  - Write instructions in the imperative and in the active voice.
  - Use one word for one meaning, and one meaning for one word.
- Read [architecture](doc/architecture.md) before you move the Tool Manager's UI or operation boundaries.
- Read the [Tool Manager guide](doc/tool-manager.md) before you change its workflows.
- Read the [settings guide](doc/settings.md) before you change schema defaults, merge rules, reload scope or settings/state precedence.
- Read the owning `doc/tsql-*.md` before you change SQL highlighting, snippets or conventions.
- `README.md` is for users: install, usage, configuration and platform notes. Put the contributor workflow in this file.
- When you change these subjects, update their doc:
  - Tool Manager behaviour: `doc/tool-manager.md`.
  - Boundaries: `doc/architecture.md`.
  - Settings: `doc/settings.md`.
  - SQL: the owning `doc/tsql-*.md`.
- Do not write counts, test totals or change history into docs, because they drift. Git history records past audits.
- Follow `.stylua.toml` and `.editorconfig`.
- Write comments only for behaviour that is not obvious.
- Never commit secrets, tokens, credentials or private machine paths.
