# Tool Manager

Open `:ToolManager` or `<leader>us`. Repeating the command focuses the existing view. A new view captures the source buffer's filename and filetype and starts in buffer scope; `s` switches between that scope and all registered tool states.

## Categories and selection

One outer frame contains category navigation, source scope, the tool list, and action hints. The selected category has a filled highlight. Narrow views retain its name; short views omit separators to keep the list usable. Formatter/linter views show priority hints when space permits.

Use `1`–`6` or Tab / Shift-Tab for LSP, DAP, Linter, Formatter, Parser, and Package. Expand an entry with `o`, Enter, or `za`. Formatter/linter groups expand by default in buffer scope and collapse by default in all-state scope, unless you have explicitly changed that group's expansion.

The selected tool stays selected after priority changes and live refreshes. Category and explicit expansion choices survive closing and reopening the manager. Help (`?` or `g?`) suspends tool actions and remains visible during background refreshes. `K` opens and focuses details so they can be scrolled. Close details with `q` or Escape to return to the tool list.

## Install and enable

`i` installs the selected Mason package or Tree-sitter parser. It does not enable a disabled runtime tool. Parsers and dependency packages support installation only; Space cannot toggle them.

Space toggles LSP, DAP, formatter, and linter tools. An already installed or external tool updates saved state and its runtime adapter immediately. With the default `missing_package_policy = "auto"`, enabling a missing Mason-backed tool first installs its package and enables it only after success. Concurrent requests for the same package share one installation. Failure leaves enablement unchanged.

Set `missing_package_policy = "manual"` in `lua/config/tool_manager.lua` to require `i` before enabling a missing package. An unavailable registry or unknown package reports an error and does not enable the tool. External tools, such as Python's environment-provided debugpy, require preparation outside Mason.

An installation continues if you close Tool Manager. Successful enablement still updates saved state and the runtime. Its completion callback cannot redraw a closed session or a later session.

## Understand status

| Status | Meaning |
| --- | --- |
| `disabled` | Saved enablement is off |
| `installing` | Its Mason installation is in progress |
| `not installed` | The managed package/parser is missing |
| `mason unavailable` / `package missing` | Registry lookup failed |
| `external` | The tool has no Mason package |
| `not configured` / `partly configured` | Runtime filetype lists do not fully match supported filetypes |
| `no binary` | Runtime command resolution found a missing executable |
| `configured`, `registered`, `ok`, diagnostic counts | Category-specific runtime health |

Installed packages do not guarantee active runtime wiring. The canonical registry describes supported tools and filetypes; initial activation remains in the owning runtime/configuration. For example, SQLFluff's linter adapter can support SQL without being included in the initial linter list. Details include the package, backend name where different, filetypes, notes, and linter errors/diagnostics.

## Priority and storage

Select a formatter or linter inside its filetype group and use `[` / `]`. Tool Manager saves the complete logical order, including disabled tools. It applies enabled tools to the runtime and preserves unrelated runtime entries. Re-enabling a tool restores its saved position.

`lua/config/tools.lua` owns logical identities, supported filetypes, Mason packages, and default priority. A `runtime_name` handles a different backend identifier: the saved YAML formatter key remains `yaml`, while Conform receives `yamlfmt`.

State lives in `stdpath('data')/tools.json`. A missing current file allows loading legacy `service.json`; malformed current state falls back to defaults. Valid saved enablement and order are merged with current definitions. Removed tools and stale/duplicate order entries do not enter active derived lists.

## View lifecycle

Nui owns mounting, layout updates, and popup buffers/windows. Each OrbitVim view session owns its event subscriptions, debounce timer, selection, and details. Normal close, external window closure, and buffer deletion dispose the session. Resize fits the layout to the available editor area; lists and details remain scrollable.

The architecture and developer checks are described in [architecture](architecture.md) and [AGENTS](../AGENTS.md).
