# AGENTS Instructions

Preserve commands, mappings and persisted state unless the task changes their contracts. Linux and Windows are equal targets.

## Git

- Write commits in [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) format.
- For a non-trivial change, write a commit body that explains why.
- Mark a breaking change with `!` and a `BREAKING CHANGE:` footer.
- Author commits as the user alone, without `Co-Authored-By` or other co-author trailers.
- Commit as the plan progresses.
- Before you push, squash related commits into one commit to keep the history clean.
- Push only after the user approves that push.
- Version releases with [Semantic Versioning 2.0.0](https://semver.org/).
- Keep `lazy-lock.json` unchanged unless dependency versions are in scope.
- Archive removed features with an annotated `archive/<name>` tag on their last commit.
- Keep plans, diagnostic logs and throwaway test output outside the repo.
- Keep credentials, personal settings and mutable application data outside Git and test inputs.

## Startup and ownership

- Preserve editor setup, Lazy bootstrap and final UI setup in that order.
- Keep settings available when personal input is invalid.
- Plugin specs declare loading and plugin keys. Their lifecycle callbacks call runtime owners.
- Importing specs must not register commands, events or mappings, or load highlight caches.
- Keep editable declarations separate from activation and resource lifetime.
- Import owners directly. Add a module only when its interface hides meaningful complexity.
- Use public Lazy and Mason interfaces.
- Keep required private Blink and Noice adaptations within their runtime owners.
- Treat configuration templates as reusable files.
- Keep project-root precedence stable when changing discovery helpers.
- Keep Harpoon mappings in its spec and pass display configuration into its runtime.

## Settings contracts

- Change public defaults in `settings.schema.json`.
- Preserve object merging, array replacement, boolean false and typed-null rejection.
- Keep startup read-only for personal settings.
- Prefer the writable data path over legacy config settings, including invalid destination input.
- Keep `vim.g.orbitvim_settings_path` as the highest-priority override.
- Create settings only through the explicit command.
- Preserve legacy bytes and competing writers during publication.
- Validate before applying live settings. Restore captured values when application fails.
- Report restoration failures separately and retain the accepted snapshot.
- Keep values marked for restart unchanged until the next startup.
- Keep tool enablement and order in the existing `tools.json` location.

## Tool contracts

- Keep logical tool definitions canonical in `config.tools`.
- Translate backend aliases through `runtime_name` at runtime boundaries.
- Keep supported filetypes separate from initial activation.
- Keep derived lists sorted and unique.
- Treat packages as dependencies that users cannot toggle.
- Mark external tools with `mason = nil`.
- Accept missing, malformed or stale `tools.json` and legacy `service.json` input.
- Preserve known saved values, complete disabled-tool order and unrelated runtime entries.
- Persist intent before applying runtime changes.
- Preserve committed intent when runtime application or lock cleanup fails.
- Recover locks only when the recorded owner is confirmed dead.
- Reject uncertain ownership instead of stealing locks by age.
- Keep the newest pending toggle authoritative when installation callbacks finish out of order.
- Enable a missing tool only after successful automatic installation.
- Keep manual installation independent from enablement.
- Keep parser and package actions limited to installation.
- Keep manager operations independent from Nui objects, cursor positions and render callbacks.
- Keep `tool.open()` and `tool.close()` as the view interface.
- Preserve help and logical selection through refresh and reordering.
- Dispose session subscriptions and timers on normal close, external close and buffer deletion.
- Let installations finish after close without redrawing a replacement session.

## Runtime contracts

- Capture buffer identity before asynchronous work.
- Keep formatting from writing source files or discarding later edits.
- Complete progress once on success, failure and buffer disposal.
- Replace subscriptions during repeated setup.
- Invalidate delayed LSP work after detach or buffer deletion.
- Preserve server-owned initialization hooks and semantic-token policy.
- Keep linter debouncing, slow-linter policy and Windows CRLF normalization.
- Build each buffer-dependent linter definition once per execution.
- Use IBL for indent rendering and Snacks for large-file detection.
- Keep automatic linting and custom parser activation disabled for detected large files.
- Preserve unexpected redraw errors with context.

## Platforms

- Detect the platform through `utils.os` in production Lua.
- Keep standalone scripts and test bootstraps independent from that module.
- Use explicit platform executable names and argument lists for native commands.
- Reserve the interactive shell for terminals.
- Build paths with `/`, which Neovim accepts on Windows.
- Use native separators for environment values such as PATH.
- Keep just recipes valid under Unix `sh` and native Windows `cmd.exe`.
- Quote recipe arguments with double quotes outside and single quotes inside when needed.
- Preserve explicit shell and compiler choices.
- Use MSYS2 UCRT64 build tools with native Git on Windows.
- Preserve `LOCALAPPDATA` when Neovim runs through MSYS Make.
- Keep the Windows ShaDa cleanup exception for `main.shada`.
- Resolve exact targets before destructive filesystem operations.

## Tests

- Add a test to the repo only when it guards behavior that no existing test covers.
- The test must fail when that behavior breaks. Weigh this before you add each test.
- Run throwaway tests freely to check your work.
- Keep throwaway tests out of the repo unless they meet the bar above.
- Name the protected contract and a mutation that breaks it in the report.
- Exercise persistence, ordering, recovery and external adapters through their entry points.
- Execute parser queries and snippet expansions instead of inspecting their declarations.
- Reject copied values, cosmetic snapshots, source substrings and mocks that reproduce implementation branches.
- Keep schema references, cross-module derivation and persisted JSON coverage.
- Never change an expectation solely to pass a failing test.
- Explain whether a changed expectation reflects a new contract, a bad test or a regression.
- Keep core specs hermetic: no network, installations, plugin updates or native tool execution.
- Use the installed Nui rather than replacing its window API.
- Restore resources and module caches even after failed assertions.
- Put fixtures below `vim.g.orbitvim_test_root` through `tests.helpers`.
- Isolate config, data, state, cache and logs from personal paths.
- Keep installed plugin sources separate from writable build fixtures.
- Fail integration suites when dependencies or required execution are missing.
- Reject skipped and pending tests through executed results.
- Preserve snippet triggers, linked placeholders and explicit assembly order.
- End complete SQL statements with a semicolon and put `$0` at the final cursor.
- Update the snippet catalog when expansions change.
- Protect transaction ownership, identifier validation and value parameterization.
- Run `just all` before you finish.
- Run `just test-integration` for parser, snippet, SQLFluff or JSON schema adapter changes.
- Run `just test-build` for native build changes.
- Run `just smoke` for startup or plugin-loading changes.
- Install `just`, StyLua and Luacheck in addition to the README runtime prerequisites.
- Core specs require pinned Plenary and Nui sources. Integration also requires SQLFluff and a JSON language server.
- Use `just --list` for recipe descriptions and `just test-spec <path>` for one spec.
- End the report with `Tests added`, `Tests updated` or `No tests added`, and its protected contract.

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
- Run the same complete suites, native build checks and startup checks on both platforms.
- Keep platform branches limited to environment preparation.
- Route behavior validation steps through just recipes.
- Cache dependency artifacts only.

## Docs

- Keep each doc concise and plain. Each sentence must carry information.
- Write English docs in US English, to the [ASD-STE100](https://www.asd-ste100.org/) writing rules:
  - Give one instruction in each sentence.
  - Write instructions in the imperative and in the active voice.
  - Use one word for one meaning, and one meaning for one word.
  - An instruction has 20 words or fewer. A description has 25 words or fewer.
- Review each sentence over these limits. Split it if it holds more than one instruction or fact.
- A list of items can stay in one sentence. Make a bullet list from more than five items.
- Write a non-English doc in two passes:
  1. Write an English draft to these rules.
  2. Translate the draft. Keep its sentence boundaries and one term for each concept.
     Keep commands, paths and code unchanged. Use the natural word order of the target language.
- Read [architecture](doc/architecture.md) before changing module or UI boundaries.
- Read [settings](doc/settings.md) before changing defaults, merge rules, reload scope or state precedence.
- Read [Tool Manager](doc/tool-manager.md) before changing tool workflows.
- Read [SQL highlighting](doc/tsql-highlighting.md) before changing queries, parsers or syntax fallback.
- Read [SQL snippets](doc/tsql-snippets.md) before changing expansions.
- Read [SQL conventions](doc/tsql-conventions.md) before changing SQL templates or examples.
- SQL fences in `doc/tsql-conventions.md` are executable parser fixtures. Preserve them during wording-only edits.
- Keep the README focused on installation, usage, configuration and platform notes.
- Keep contributor constraints here and operator procedures in the feature guides.
- Update the owning guide when its public contract changes.
- Keep test totals and change history out of prose.
- Preserve measured data and release history when editing their presentation.
- Follow `.stylua.toml` and `.editorconfig`.
- Explain non-obvious behavior in comments.
