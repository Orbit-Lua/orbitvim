# Tool Manager

OrbitVim uses [hangar.nvim](https://github.com/Orbit-Lua/hangar.nvim) as its Tool Manager. This guide covers OrbitVim's keys, settings, registry and state. The [hangar guide](https://github.com/Orbit-Lua/hangar.nvim/blob/main/doc/guide.md) covers the view, statuses, locks and session behavior.

Open Tool Manager with `:ToolManager` or `<leader>us`. If it is open, this focuses the existing view. A new session captures the filetype and filename of the source buffer. `s` switches between that buffer and all registered tools.

## Navigation

Use `1`–`6` or Tab / Shift-Tab to select LSP, DAP, Linter, Formatter, Parser or Package. `K` focuses details. `?` or `g?` toggles help. `q` or Escape closes the view or returns from details.

Set `tool_manager.layout` in settings to change the spacing in cells: `padding`, `column_gap`, `gap` and `margin`. Set `tool_manager.width`, `height` and `details.width` to change the window sizes. Saving the settings file updates an open view.

## Install and enable

`i` installs a Mason package or parser without enabling a disabled runtime tool. Space toggles an LSP, DAP, formatter or linter.

With `tool_manager.missing_package_policy = "auto"`, a missing Mason package installs first. To require explicit installation, set it to `"manual"` in settings. External dependencies, such as debugpy from the environment, need setup outside Mason. Mark such a tool with `mason = nil` in `config.tools`.

## Status

Each status icon has its own highlight group: `HangarIconEnabled`, `…Idle`, `…Info`, `…Installing`, `…Warning`, `…Error`, `…Unknown` and `…Disabled`. Category tabs use `HangarCategoryActive` and `HangarCategoryInactive`, which `chadrc.lua` colors. To override a group, define it in your color scheme or configuration.

Registry support lists do not override the initial formatter and linter activation in `config.formatter` and `config.linter`. For example, a tool can support Markdown but be configured only for web filetypes.

## Priority and persistence

Use `[` / `]` on a formatter or linter to change its priority for a filetype. `tools.formatter_defaults` and `tools.linter_defaults` in settings set the initial order. Valid saved order overrides them.

The registry in `config.tools` uses logical IDs. At runtime, adapters translate them to backend aliases, for example `yaml` to Conform's `yamlfmt`.

State is stored in `stdpath('data')/tools.json`, or in `vim.g.tool_state_path` when it is set. If the file is missing, hangar reads the legacy `service.json`. See the hangar guide for locks, recovery and merging.

## Session lifetime

hangar owns the windows, subscriptions and timers of each view. See [architecture](architecture.md) for OrbitVim's composition of hangar.
