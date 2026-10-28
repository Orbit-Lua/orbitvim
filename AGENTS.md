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
- Pin each dependency to a revision that exists on its remote.
- Archive removed features with an annotated `archive/<name>` tag on their last commit.
- Keep plans, diagnostic logs and throwaway test output out of tracked files.
- Keep credentials, personal settings and mutable application data outside Git and test inputs.

## Code

- Keep editable declarations separate from activation and resource lifetime.
- Import owners directly. Add a module only when its interface hides meaningful complexity.
- Use public plugin interfaces. Keep each required private adaptation within its runtime owner.
- Capture buffer identity before asynchronous work.
- Replace subscriptions during repeated setup.
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
- Resolve exact targets before destructive filesystem operations.

## Tests

- Add a test to the repo only when it guards behavior that no existing test covers.
- The test must fail when that behavior breaks. Weigh this before you add each test.
- Run throwaway tests freely to check your work.
- Keep throwaway tests out of the repo unless they meet the bar above.
- Name the protected contract and a mutation that breaks it in the report.
- Exercise persistence, ordering, recovery and external adapters through their entry points.
- Reject copied values, cosmetic snapshots, source substrings and mocks that reproduce implementation branches.
- Never change an expectation solely to pass a failing test.
- Explain whether a changed expectation reflects a new contract, a bad test or a regression.
- Keep core specs hermetic: no network, installations, plugin updates or native tool execution.
- Restore resources and module caches even after failed assertions.
- Isolate config, data, state, cache and logs from personal paths.
- Prepare conditional dependencies with fixtures. Do not skip them.
- Fail integration suites when dependencies or required execution are missing.
- Reject skipped and pending tests through executed results.
- Reject uncaught editor errors through executed test results.
- Run `just all` before you finish.
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
- Review each sentence over these limits. Split it if it holds more than one instruction or fact. A list of items can stay in one sentence. Make a bullet list from more than five items.
- Write a non-English doc in two passes:
  1. Write an English draft to these rules.
  2. Translate the draft. Keep its sentence boundaries and one term for each concept. Keep commands, paths and code unchanged. Use the natural word order of the target language.
- Keep the README focused on installation, usage, configuration and platform notes.
- Keep general contributor rules here. Keep feature contracts and operator procedures in the feature guides.
- Update the owning guide when its public contract changes.
- Keep test totals and change history out of prose.
- Preserve measured data and release history when editing their presentation.
- Follow `.stylua.toml` and `.editorconfig`.
- Explain non-obvious behavior in comments.
- Read [architecture](doc/architecture.md) before you change startup, module boundaries, runtime behavior or a shared-task owner.
- Read [settings](doc/settings.md) before you change defaults, merge rules, reload scope or state precedence.
- Read [Hangar](doc/hangar.md) before you change tool workflows, tool state or the tool registry.
- Read [testing](doc/testing.md) before you add a test, a fixture or a CI step, and before you finish.
- Read [SQL highlighting](doc/tsql-highlighting.md) before you change queries, parsers or syntax fallback.
- Read [SQL snippets](doc/tsql-snippets.md) before you change expansions.
- Read [SQL conventions](doc/tsql-conventions.md) before you change SQL templates, examples or that guide's SQL fences.
