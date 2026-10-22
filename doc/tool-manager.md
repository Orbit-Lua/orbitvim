# Tool Manager

Open `:ToolManager` or `<leader>us`. Reopening focuses the existing view. A new session captures the source buffer's filetype and filename; `s` switches between that buffer and all registered tools.

## Navigation

Use `1`–`6` or Tab / Shift-Tab to select LSP, DAP, Linter, Formatter, Parser or Package. Buffer-scope formatter and linter lists show saved ranks; all-state lists group by filetype. Expand a group with `o`, Enter or `za`.

Logical selection survives reordering, resizing and refreshes. Category and expansion choices survive reopening. Help (`?` or `g?`) suspends tool actions and stays visible during refresh. `K` focuses scrollable details; `q` or Escape returns to the list. Details appear beside the list, below it, or on demand as space permits.

## Install and enable

`i` installs a Mason package or parser without enabling a disabled runtime tool. Parsers and dependency packages support installation only.

Space toggles an LSP, DAP, formatter or linter. Installed and externally managed tools update saved intent and runtime immediately. With `missing_package_policy = "auto"`, a missing Mason package installs first and enables only after success. Concurrent requests share one installation; failure preserves enablement.

Set `tool_manager.missing_package_policy = "manual"` in settings to require explicit installation before enabling a missing package. An unknown package or unavailable registry reports failure. External dependencies such as environment-provided debugpy require setup outside Mason.

Operations persist intent before runtime changes. A backend failure remains in details until a successful operation clears it; saved intent remains available at startup. Installations continue after the view closes, but callbacks cannot redraw a closed or replacement session.

## Status

| Status | Meaning |
| --- | --- |
| `Disabled` | Global saved enablement is off |
| `Installing…` | Mason installation is running |
| `Not installed` | Required package or parser is absent |
| `Unknown` | Registry or backend availability cannot be confirmed |
| `Not configured` / `Partly configured` | Runtime wiring is missing for part or all of the selected scope |
| `Missing executable` | Command resolution failed |
| `Not active` | Saved enablement is on but runtime activation is absent |
| `Configured`, `Registered…`, `Running…`, `Idle` | Category-specific runtime health |
| `Diagnostics: …` | Findings in source code |
| `Failed` | An operation failed to execute |

Installation, management source, runtime health and enablement are distinct facts in details. Installation alone does not activate a tool. Registry support lists do not override initial formatter/linter activation: a tool may support Markdown while being configured only for web filetypes.

## Priority and persistence

Use `[` / `]` on a formatter or linter in buffer scope or an expanded filetype group. Priority is per filetype; enablement is global to the tool. Saved order includes disabled tools and is restored when they are enabled again. Reordering preserves unrelated runtime entries.

The canonical registry uses logical IDs; adapters translate backend aliases such as `yaml` to Conform's `yamlfmt` at runtime.

State is stored in `stdpath('data')/tools.json`. A missing file permits migration from legacy `service.json`; malformed current state falls back to defaults. Valid values merge with current definitions, excluding removed tools and stale or duplicate order entries.

Writes take an exclusive lock, reread disk state, merge the selected change and replace the file atomically, preserving unrelated changes from another instance. Refused replacement preserves old disk state and leaves the requested runtime change unapplied. Retry a busy lock after its writer finishes; abandoned locks are replaced. Another instance's write does not refresh an already open manager automatically.

## Session lifetime

Nui owns windows and mounting. Each view owns subscriptions, debounce timers, source context and selection. Normal close, external window closure and buffer deletion dispose the session. Lists and details stay scrollable when the layout shrinks. See [architecture](architecture.md) for module boundaries.
