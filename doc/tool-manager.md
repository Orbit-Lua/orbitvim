# Tool Manager

Tool operations save intent before applying runtime changes. If a backend raises or returns a failure, the operation reports failure and the tool's details retain the error. The saved choice remains available for the next startup. A later successful operation clears the error.

Open `:ToolManager` or `<leader>us`. Repeating the command focuses the existing view. A new view captures the source buffer's filename and filetype and starts in buffer scope; `s` switches between that scope and all registered tool states.

## Categories and selection

One outer frame contains category navigation, source scope, the tool list, and action hints. The list keeps `Tool`, `Enabled`, and `Status` columns. The selected category has a filled highlight. Narrow views retain its name; short views omit separators to keep the list usable. Formatter/linter views show priority hints when space permits.

Use `1`–`6` or Tab / Shift-Tab for LSP, DAP, Linter, Formatter, Parser, and Package. Expand a formatter/linter group with `o`, Enter, or `za` in all-state scope.

The selected tool stays selected after priority changes, resize, and live refreshes. Buffer-scope formatter/linter lists are flat and show saved ranks; all-state views retain filetype groups for reordering. Other categories show a flat tool list. Category and explicit expansion choices survive closing and reopening the manager. Help (`?` or `g?`) suspends tool actions and remains visible during background refreshes. A wrapped details preview follows selection without moving focus on wide and medium editors. `K` focuses the details so they can be scrolled; close it with `q` or Escape to return to the tool list. Wide views place details beside the list, medium views below it, and tiny views show details only after `K`.

## Install and enable

`i` installs the selected Mason package or Tree-sitter parser. It does not enable a disabled runtime tool. Parsers and dependency packages support installation only; Space cannot toggle them.

Space toggles LSP, DAP, formatter, and linter tools. An already installed or external tool updates saved state and its runtime adapter immediately. With the default `missing_package_policy = "auto"`, enabling a missing Mason-backed tool first installs its package and enables it only after success. Concurrent requests for the same package share one installation. Failure leaves enablement unchanged.

Set `tool_manager.missing_package_policy` to `"manual"` in `settings.json` to require `i` before enabling a missing package. An unavailable registry or unknown package reports an error and does not enable the tool. External tools, such as Python's environment-provided debugpy, require preparation outside Mason.

An installation continues if you close Tool Manager. Successful enablement still updates saved state and the runtime. Its completion callback cannot redraw a closed session or a later session.

## Understand status

| Status | Meaning |
| --- | --- |
| `Disabled` | Saved global enablement is off; details still show installation and runtime facts |
| `Installing…` | Its Mason installation is in progress |
| `Not installed` | The managed package/parser is missing |
| `Unknown` | Availability cannot be confirmed; details show registry/backend failures |
| `Not configured` / `Partly configured` | Runtime wiring is missing for the current scope |
| `Missing executable` | Runtime command resolution found a missing executable |
| `Not active` | Saved enablement is on, but the runtime has not enabled this tool |
| `Configured`, `Registered…`, `Running…`, `Idle` | Category-specific runtime health |
| `Diagnostics: …` | Source-code findings, not a failed tool process |
| `Failed` | A tool operation reported an execution failure |

Installed packages do not guarantee active runtime wiring. The canonical registry describes supported tools and filetypes; initial activation remains in the owning runtime/configuration. For example, SQLFluff's linter adapter can support SQL without being included in the initial linter list. The list uses icons and English status labels; Enabled is On/Off, or N/A for installation-only categories. External management is a source, not a runtime status. Details separate installation, source, runtime status, and enablement; they include filetypes, notes, and linter errors/diagnostics where available.

## Priority and storage

Select a formatter or linter in buffer scope, or inside an all-state filetype group, and use `[` / `]`. Tool Manager saves the complete logical order, including disabled tools. Enablement applies globally to that tool; priority applies to the selected filetype. Reordering changes the priority of currently configured tools and preserves unrelated runtime entries; it does not activate every supported tool. Re-enabling a tool restores its saved position.

`lua/config/tools.lua` owns logical identities, supported filetypes, Mason packages, and default priority. A `runtime_name` handles a different backend identifier: the saved YAML formatter key remains `yaml`, while Conform receives `yamlfmt`.

State lives in `stdpath('data')/tools.json`. A missing current file allows loading legacy `service.json`; malformed current state falls back to defaults. Valid saved enablement and order are merged with current definitions. Removed tools and stale/duplicate order entries do not enter active derived lists. State writes lock, reread the latest disk values, merge the selected change and replace the file atomically. Separate instances therefore retain each other's unrelated changes. A refused replacement preserves the previous persisted state and does not apply the unsaved change to the runtime.

A busy `tools.json.lock` reports an error instead of overwriting another writer. Retry after the other operation completes. If a process crashed and left a stale lock, close all Neovim instances before removing that exact lock file. Other instances' writes do not automatically refresh an already open manager or its runtime.

## View lifecycle

Nui owns mounting, layout updates, and popup buffers/windows. Each OrbitVim view session owns its event subscriptions, debounce timer, selection, and details. Normal close, external window closure, and buffer deletion dispose the session. Resize fits the layout to the available editor area; lists and details remain scrollable.

The architecture and developer checks are described in [architecture](architecture.md) and [AGENTS](../AGENTS.md).
