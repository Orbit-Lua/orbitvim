# Test audit

The development audit reviewed existing cases against AGENTS.md: unique observable contracts, independent expectations, hermetic core seams, real integration dependencies, and cleanup after failure. Passing a suite alone does not establish admission.

The table groups cases by spec. Mutations describe production changes that must invalidate the retained behavior. No test is admitted solely because its file or export exists.

| Spec | Decision and protected contract | Breaking mutation |
| --- | --- | --- |
| `config_formatter` | Keep executable/path and SQLFluff context adapters. | Drop the context filename or Windows command suffix. |
| `config_linter` | Replace helper-derived expectations with independently specified SQLFluff arguments and project cwd. | Resolve against the wrong buffer. |
| `config_packages` | Keep deterministic cross-module registry derivation. | Omit a category or retain duplicate packages. |
| `config_tools` | Keep schema and cross-reference validation. | Reference an unknown tool or unsupported filetype in defaults. |
| `core_keymaps` | Keep path escaping, hover eligibility and help suppression regressions; isolate mappings and windows. | Interpolate an unescaped project path or allow unrelated help. |
| `plugins_noice` | Keep execution of the formatter notification predicate at the Noice seam. | Reject formatter lifecycle notifications. |
| `roslyn_target` | Keep candidate membership and ambiguous-root selection. | Choose an excluded or ambiguous solution. |
| `runtime_dap` | Keep activation filtering and detached configurations. | Register a disabled adapter or mutate the input definitions. |
| `runtime_formatter_options` | Keep fresh options, persisted logical aliases and disabled-tool filtering. | Reuse a mutated options table or filter by runtime ID. |
| `runtime_formatter` | Keep asynchronous completion, failures and overlap rejection; remove the alias case covered by formatter options. | Leave formatting active after completion or permit overlapping runs. |
| `runtime_linter` | Keep buffer capture, generation changes and wiped-buffer cancellation. | Run a stale timer in the current buffer. |
| `test_bootstrap` | Keep state/log/ShaDa isolation; add failed-case cleanup and fixture containment. | Leak a timer/cache entry after an assertion or permit an escaping fixture path. |
| `tool_category_dap` | Keep backend availability, adapter/configuration health and dotnet enable/disable transitions. | Count another adapter's configurations or retain disabled configurations. |
| `tool_category_formatter` | Fix setup/teardown isolation; keep ordered re-enable, aliases, scoped wiring and executable-vs-condition distinction. | Re-enable at the wrong position or classify a condition failure as a missing binary. |
| `tool_category_linter` | Keep wiring and executable health at the backend seam. | Report an unwired or missing executable as ready. |
| `tool_category_package` | Remove label/summary cases for unused methods; protect dependency installation through `tool.manager` instead. | Pass the wrong logical ID to the installer or mutate saved state during manual installation. |
| `tool_category_parser` | Keep installer async result handling; remove label/summary cases for unused methods. | Report success before confirmation or accept a missing task. |
| `tool_data` | Keep derived grouping, ordering and independent installation/enablement/runtime facts; remove the summary arithmetic case with no state transition. | Hide a missing installation behind saved enablement or confuse source diagnostics with execution failure. |
| `tool_manager` | Keep detached snapshots, persistence-before-runtime, install policy, capabilities and complete ordering. | Enable after failed installation, apply after failed persistence or lose disabled tools. |
| `tool_mason` | Keep package lookup, shared pending operations and subscription disposal. | Start two installs or retain an observer after disposal. |
| `tool_order` | Keep stale/duplicate reconciliation and unrelated runtime entries. | Drop an external tool or repeat a saved tool. |
| `tool_state` | Keep current/legacy JSON, malformed values, persistence and atomic-write recovery. | Accept malformed enablement or change memory after refused replacement. |
| `tool_ui` | Keep public interactions with installed Nui, stable selection, help, narrow layouts and session disposal. | Refresh a closed/replaced session, act through help or place details outside the editor. |
| `utils_cmp` | Keep ordered completion action dispatch; isolate injected actions. Remove repair/session cases with the unused native snippet repair code. | Run an action after acceptance. |
| `runtime_blink` | Move Blink adapter cases with their runtime owner, preserving the same contract coverage. | Lose a configured provider, bypass Tab actions or retain old window dimensions after resize. |
| `utils_fs` | Keep project-root selection, filesystem filtering and skip-rule deletion safety. | Prefer cwd over explicit context or delete `main.shada`. |
| `utils_icons` | Keep provider selection/fallback; remove the standalone cosmetic highlight-string case. | Invoke the fallback provider despite an available primary provider. |
| `utils_logger` | Keep persisted records, defensive copies, channel isolation and bounded eviction. | Mutate stored messages through returned data or evict newest records. |
| `runtime_lsp_client` (formerly `utils_lsp`) | Restore the original module cache; keep client/method filtering and capability refresh opt-in through public attachment events. | Replay a non-refreshable callback or route another client's attachment. |
| `utils_os` | Remove the standalone date-wrapper spec under the excluded-helper rule. | No independently admitted feature-level contract. |
| `utils_progress` | Restore module cache and finish progress during teardown; keep message lifecycle and timer cancellation. | Continue updating after completion. |
| `core_shell` (formerly `utils_shell`) | Replace the architecture-branch mirror with explicit user-choice preservation and executable availability. | Overwrite the selected shell/compiler or select a missing compiler. |
| `utils_sqlfluff` | Keep config discovery, template constraints and shared executable context. | Select another tool's config or override a project config. |
| `utils_str` | Keep multibyte display-width safety; remove cosmetic padding cases. | Split a multibyte glyph or exceed the available display columns. |
| `utils_table` | Remove with the unused message-key deduplication helper; exercise TypeScript diagnostic forwarding directly. | No remaining production consumer. |
| `utils_term` | Keep the gsub multiple-return regression and managed-window eligibility. | Forward gsub's count to jobstart or toggle from an unrelated float. |
| `utils_window` | Keep real floating-window identification; remove fixed sizing assertions covered by live UI constraints. | Treat an editor split as a floating window. |
| `sqlfluff` integration | Keep real executable dialect behavior; missing executable fails. | Ignore first-line dialect directives. |
| `treesitter_injections` integration | Keep real parser injection, escape eligibility, deduplication and independent switches. | Inject escaped text or duplicate marked SQL-named strings. |
| `treesitter_tsql` integration | Keep real captures, syntax scopes and configured/explicit dialect behavior. | Match strings/comments as keywords or override an explicit dialect. |
| `treesitter_tsql_corpus` integration | Keep executing documented fences through actual parsers and syntax. | Leave documented SQL fences unparsed or fallback matches outside their scopes. |
| `tsql_snippets` integration | Replace docstring inspection and label inventories with actual LuaSnip expansions, parameters and SQL safety checks. | Break a placeholder mirror or expand an unsafe query template. |

The bootstrap isolates hooks and failed cases: module/preload caches, global and existing-buffer mappings, global/buffer/window options, globals, new buffers/windows, autocmds and timers. Individual specs still restore mutated dependency objects and environment variables. The validator rejects explicit pending/skip forms; dependency assertions and human contract review remain necessary.

The UI specs exceed three scenarios and 80 lines because they exercise one real Nui session across selection, asynchronous completion, help, resize and disposal transitions. Parser matrices protect distinct grammar forms and escape rules. SQLFluff discovery covers five external configuration formats. These are behavioral matrices, not size or coverage targets.

The YAML registration regression executes `runtime.lsp.register_servers` against the Neovim LSP seam; moving YAML options back outside `servers.yamlls` fails it. Tool Manager's added failure transition preserves saved intent, reports the backend error and clears it after success; removing the protected apply call fails it. These extend the behavioral contracts rather than asserting configuration tables in isolation.

Settings cases cover independent contracts: partial/default resolution, typed/reference rejection, saved-file observation without tool-state writes, validation/apply rollback, restart scope with source provenance, and saved-order precedence. They exceed the usual three-case/80-line review threshold because these are separate state transitions across the public loader, runtime owner and persistence seam. They do not repeat a validator's branches as mocked outcomes.

The settings command case executes the mapping, creates a schema reference and preserves an invalid existing file through startup recovery. The real Nui settings case verifies save-triggered resize, help and selection. Inlay hint application tests restoration after a failed client update. JSON schema integration requests real enum completions and pull diagnostics from `json-lsp`; a missing dependency fails the suite. The integration handshake exceeds 80 lines because it owns the actual process, document synchronization and cleanup.

The existing manual-install-policy case now loads that policy from JSON through the settings owner, so it also protects the handoff to actual manager operations.

The multiline JSON case also exposed a fixture bug: `writefile` encoded embedded newlines as NUL bytes when given one multiline list item. The helper now splits string content into lines before writing.

The bootstrap redirects `XDG_STATE_HOME` below the test root as well, so the real JSON client's Neovim LSP log stays isolated. Schema integration uses the production file association without a `$schema` marker, including Windows drive normalization.

The parser/package label and summary methods and `tool.data.state_summary` had no production callers. Their removal simplifies the private adapters without removing a user feature. Dependency installation is now checked through the public manager, including logical identity, failure callback and unchanged persistence.

## Mutation verification

Temporary edits were restored byte-for-byte after each run. Each mutation produced an assertion failure, not a runner error:

| Mutation | Detecting contract |
| --- | --- |
| Replace the schema's `manual` enum value. | Real JSON server policy completion. |
| Omit the settings owner's rollback calls. | Failed application restores editor values and accepted settings. |
| Remove `QUOTENAME` from the dynamic-identifier template. | Actual LuaSnip expansion retains identifier quoting. |
| Retain newly loaded modules during failed-case cleanup. | Test bootstrap restores module caches after an exception. |
| Add conceal metadata to Markdown fence captures. | Real-parser notes query assertion detects hidden fences. |

## Reliability follow-up

The confirmed defects below are fixed. Each regression was reproduced before its fix, except the Markdown query extraction, which preserves behavior and gains a real-parser contract. The shell cases replace tests that mirrored the old implementation. Removed native snippet repair, undo and padding wrappers had no production callers; no public mapping or command was removed.

| Contract and owning spec | Breaking mutation |
| --- | --- |
| Pyright regeneration captures the project and restores old stubs after spawn/process failure (`python_command`). | Delete the old directory before starting Pyright, or use the cwd after selection. |
| `TSInstallAll` installs the canonical derived parser list (`treesitter_command`). | Treat a Lazy opts callback as an already resolved table. |
| LuaSnip's build links a loadable Lua extension from a path containing spaces (`plugin_build` integration). | Omit the Windows Neovim directory or concatenate the install target into linker flags. |
| Schema-valid details widths fit a real Nui session (`tool_ui`). | Reserve the entire preferred width when it exceeds available columns. |
| Reordering preserves the configured activation set and full saved order (`tool_manager`). | Activate Deno while moving Markdown TOC. |
| A one-field editor reload preserves unrelated local values (`settings`). | Reapply all editor defaults. |
| Inlay toggles affect only the requested buffer (`runtime_lsp_client`). | Omit the buffer scope from the Neovim API call. |
| TypeScript forwarding retains identical messages at different locations (`typescript_diagnostics`). | Deduplicate by message alone. |
| Dynamic hover eligibility uses the requested buffer (`core_keymaps`). | Query the current buffer instead of the attachment buffer. |
| Detach/reattach reinitializes the same client's supported methods (`runtime_lsp_client`). | Keep the detached buffer in the supported-method cache. |
| Formatter health resolves against the captured source (`tool_manager`). | Ask Conform about the popup buffer. |
| Unavailable runtime backends report failed operations (`tool_manager`, `tool_category_dap`). | Swallow failed backend imports. |
| Failed settings/inlay rollback remains visible with the original apply error and restart guidance (`settings`, `runtime_lsp`). | Ignore errors raised by undo callbacks. |
| Independent state writers merge unrelated changes and refuse a busy lock (`tool_state`). | Save a stale cached snapshot or write without the exclusive lock. |
| Harpoon selects literal filenames containing pattern characters (`runtime_harpoon`). | Interpret the rendered filename as a Lua pattern. |
| Failed-case cleanup restores existing buffer-local mappings (`test_bootstrap`). | Restore only global mappings. |
| Shell setup preserves explicit choices and detects available defaults (`core_shell`). | Always force PowerShell and GCC. |
| Markdown headings remain highlighted and fences remain visible (`notes_query` integration). | Retain conceal metadata on fence/language captures. |

The Pyright spec exceeds 80 lines because it owns command selection, process callbacks, project changes, filesystem recovery and cleanup across three distinct outcomes. Settings and Tool Manager additions extend existing state-transition specs; each new case protects a separate contract. The Markdown case executes the production query against the installed parser instead of inspecting source text.

Two test corrections preserve existing contracts: repeated failed `require` calls may return Lua's previous-load error, so the DAP assertion checks the owning availability error; root-marker cases restrict their marker list so an enclosing repository's `.git` cannot mask the fixture marker. Neither change alters product root-selection policy.

Validation passed `just all` (145 core cases), `just test-integration` (50 integration cases) and the standard startup smoke command without sandbox adapters.

Windows CI exposed an incomplete runtimepath in the test bootstrap: changing to a fixture directory made uncached application modules unavailable when the repository was outside Neovim's default configuration path. The bootstrap now captures absolute repository and `after` paths. Existing Python regeneration, Harpoon selection and parser cases reproduce the failures with an empty configuration home and pass with the fix; no test expectation changed. Replacing the absolute entry with `.` breaks module loading; omitting `after` loses the production parser queries.

## Fresh installation acceptance

Acceptance used separate XDG configuration, data, state and cache directories. It downloaded plugins, compiled the integration parsers, installed JSON LSP through Mason and verified all 43 installed plugin revisions against the bundled lockfile. Both suites also passed against these newly installed dependencies.

Two real Neovim processes verified saved settings, explicit reload in another instance, deferred settings after restart, and independent tool-state writes. A real Mason install completed after closing Tool Manager without replacing a later session or its help. Hash comparisons confirmed that personal settings and tool state were unchanged.

| Newly reproduced defect | Regression contract | Breaking mutation |
| --- | --- | --- |
| Windows Makefile detection left LuaSnip's linker flags empty. | Compile and load a Lua extension using the public build callback (`plugin_build`). | Remove the resolved Neovim directory argument. |
| Markdown preview used the selected shell and returned before installation completed. | Execute the installer and its versioned output before returning (`plugin_build`). | Restore the asynchronous Vim build command. |
| A fresh Lazy bootstrap used stable rather than the bundled revision. | Clone a local Git fixture whose stable revision differs from the lock (`bootstrap`). | Remove checkout of the locked revision. |

The earlier build test captured shell arguments but could pass while linking failed. It now executes a compiler and loads the result in a child Neovim. The two adapter cases exceed 80 lines because they own native fixtures, subprocesses, shell behavior and failure cleanup; they cover separate installation contracts. The bootstrap fixture needs about 80 lines to own two Git revisions, an isolated configuration and child startup; its local remote performs no network access. All three regressions failed before their corresponding fixes and passed afterward.
