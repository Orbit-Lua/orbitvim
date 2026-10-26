# Tool Manager

Open Tool Manager with `:ToolManager` or `<leader>us`. If it is open, this focuses the existing view. A new session captures the filetype and filename of the source buffer. `s` switches between that buffer and all registered tools.

## Navigation

Use `1`–`6` or Tab / Shift-Tab to select LSP, DAP, Linter, Formatter, Parser or Package. Buffer-scope formatter and linter lists show saved ranks. All-state lists group by filetype. Expand a group with `o`, Enter or `za`.

Logical selection survives reordering, resizing and refreshes. Category and expansion choices survive reopening. Help (`?` or `g?`) suspends tool actions and stays visible during refresh. `K` focuses scrollable details. `q` or Escape returns to the list. Details show beside the list, below it or on demand, as the space permits.

## Install and enable

`i` installs a Mason package or parser without enabling a disabled runtime tool. Parsers and dependency packages support installation only.

Space toggles an LSP, DAP, formatter or linter. Installed and externally managed tools update saved intent and runtime immediately. With `missing_package_policy = "auto"`, a missing Mason package installs first. The tool is enabled only after success. Concurrent requests share one installation. A newer toggle supersedes pending intent. Older completion cannot restore superseded enablement. A failure keeps the enablement.

To require explicit installation before a missing package is enabled, set `tool_manager.missing_package_policy = "manual"` in settings. An unknown package or an unavailable registry reports a failure. External dependencies, such as debugpy from the environment, need setup outside Mason.

Operations persist intent before runtime changes. A backend failure stays in details until a successful operation clears it. Saved intent stays available at startup. Installations continue after the view closes. Their callbacks cannot redraw a closed session or a replacement session.

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

Installation, management source, runtime health and enablement are distinct facts in details. Installation alone does not activate a tool. Registry support lists do not override the initial formatter/linter activation. For example, a tool can support Markdown but be configured only for web filetypes.

## Priority and persistence

Use `[` / `]` on a formatter or linter in buffer scope or in an expanded filetype group. Priority applies per filetype. Enablement is global to the tool. Saved order includes disabled tools. It is restored when they are enabled again. Reordering preserves unrelated runtime entries.

The canonical registry uses logical IDs. At runtime, adapters translate them to backend aliases, for example `yaml` to Conform's `yamlfmt`.

State is stored in `stdpath('data')/tools.json`. If the file is missing, a migration from the legacy `service.json` can occur. A malformed current state falls back to defaults. Valid values merge with the current definitions. Removed tools and stale or duplicate order entries are left out.

A write takes an exclusive lock and reads the disk state again. Then it merges the selected change and replaces the file atomically. Unrelated changes from another instance stay. If the replacement is refused, the old disk state stays and the requested runtime change does not apply. If the lock is busy, try again after its writer finishes. Locks record a PID and ownership token. Recovery requires a confirmed dead process. Live locks are never stolen because of age. Malformed locks and abandoned recovery guards require operator inspection. Confirm that no writer owns the state before removing them. A cleanup failure reports saved intent separately from unchanged runtime. A write from another instance does not refresh a manager that is already open.

## Session lifetime

Nui owns windows and mounting. Each view owns subscriptions, debounce timers, source context and selection. Normal close, external window closure and buffer deletion dispose the session. Lists and details stay scrollable when the layout shrinks. See [architecture](architecture.md) for module boundaries.
