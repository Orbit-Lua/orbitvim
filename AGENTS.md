# AGENTS Instructions

Preserve commands, mappings and persisted state unless the task changes their contracts. Linux and Windows are equal targets.

## Git

- Write commits in [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) format.
- Start the type, the scope and the description in lowercase. Keep the case of code identifiers and proper nouns.
- For a non-trivial change, write a commit body that explains why.
- Mark a breaking change with `!` and a `BREAKING CHANGE:` footer.
- Author commits as the user alone. Add no agent trailers or links, such as `Co-Authored-By` or a session URL.
- Commit as the plan progresses.
- Before you push, squash related commits into one commit to keep the history clean.
- Push only after the user approves that push.
- Keep `lazy-lock.json` unchanged unless dependency versions are in scope.
- Pin each dependency to a revision that exists on its remote.
- Archive removed features with an annotated `archive/<name>` tag on their last commit.
- Keep plans, diagnostic logs and throwaway test output out of tracked files.
- Keep credentials, personal settings and mutable application data outside Git and test inputs.

## Releases

- Version releases with [Semantic Versioning 2.0.0](https://semver.org/).
- Name release tags with bare versions, such as `1.2.3`. Preserve an established tag prefix.
- Use [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) when you create a changelog. Preserve an existing changelog's format.
- Use `1.2.3-rc.1` for a release candidate.
- Prepare a release in this order:
  1. Update applicable version files and the changelog in one commit, such as `chore(release): prepare 1.2.3`.
  2. Push the commit to `main` after approval.
  3. Wait until that commit's branch validation passes.
  4. Create an annotated tag: `git tag -a 1.2.3 -m "Release 1.2.3" <commit>`.
  5. Push the tag alone after approval: `git push origin 1.2.3`.
- Push the commit and tag separately. Do not use `git push --follow-tags`.
- Separate pushes prevent overlapping branch and tag pipelines from competing for a runner.
- Configure release automation before relying on tag pushes to build, smoke-test, publish or create a release.

## Code

- Keep editable declarations separate from activation and resource lifetime.
- Import owners directly. Add a module only when its interface hides meaningful complexity.
- Use public plugin interfaces. Keep each required private adaptation within its runtime owner.
- Keep each shared task with its documented owner.
- Leave Hangar view defaults and state persistence to hangar.nvim.
- Keep OrbitVim's registry and runtime adapters in OrbitVim.
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
- Run validation on pull requests, pushes to `main` and manual dispatches.
- Keep checks in branch workflows. Use a separate tag workflow when you add release automation.
- Run release jobs only for version tags. Match the complete version with `^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$`.
- Filter release tag pushes with `[0-9]+.[0-9]+.[0-9]+` and `[0-9]+.[0-9]+.[0-9]+-*` globs.
- Start each release job by checking that the tagged commit belongs to `main`.
- Check out release jobs with `fetch-depth: 0` so the ancestry check can see the default branch.
- Protect release tags with a tag ruleset.
- Keep release credentials in an environment that allows only release tags.
- A tag workflow uses the tagged commit's CI configuration. Merge CI changes to `main` before tagging.
- After you change these rules, audit the repo against them.
- Validate changes locally. Then verify the required CI on the pushed commit.
- Report each uncovered contract and each unavailable check.
- Run the complete suites, native build checks and startup checks in CI on Linux.
- Run the same recipes locally on Windows before each push. CI does not cover Windows.
- Route behavior validation steps through just recipes.
- Cache dependency artifacts only.

## Docs

- Keep each doc concise and plain. Each sentence must carry information.
- Write only standing rules in `AGENTS.md`. A standing rule changes how an agent does later, unrelated tasks.
- Record each local fact or failure at its source: a code comment, test, commit body, ADR or issue.
- Write English docs in US English, to the [ASD-STE100](https://www.asd-ste100.org/) writing rules:
  - Give one instruction in each sentence.
  - Write instructions in the imperative and in the active voice.
  - Use one word for one meaning, and one meaning for one word.
  - An instruction has 20 words or fewer. A description has 25 words or fewer.
- Review each sentence over these limits. Split it if it holds more than one instruction or fact.
- Use a numbered list for three or more instructions in a fixed order, also across sentences.
- Use bullet lists for full-sentence items or sets with more than five items.
- Keep other sets in one sentence when useful, even when the sentence exceeds the word limits.
- Write a non-English doc in two passes:
  1. Write an English draft to these rules.
  2. Translate the draft:
     1. Keep its sentence boundaries and one term for each concept.
     2. Keep commands, paths and code unchanged.
     3. Use the natural word order of the target language.
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
