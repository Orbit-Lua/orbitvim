# Hangar integration

OrbitVim uses [hangar.nvim](https://github.com/Orbit-Lua/hangar.nvim) to manage its tools. This guide defines OrbitVim's entry points, settings, registry and state paths.

The [upstream guide](https://github.com/Orbit-Lua/hangar.nvim/blob/0a78244ecfb5c84ac4160653a12c39b22a8dc237/doc/guide.md) defines operations, keys, statuses, persistence and recovery. These links match the revision in `lazy-lock.json`.

## Entry points and settings

Open Hangar with `:Hangar` or `<leader>us`. Open personal settings with `:OrbitSettings` or `<leader>uc`.

Set view overrides in the `hangar` section of personal settings. The bundled `settings.schema.json` defines accepted fields and bounds. Hangar supplies omitted view defaults. `:OrbitSettings info` identifies them as `hangar default`.

Saving settings refreshes an open view. Removing an override restores its plugin default. See [settings](settings.md) for reload scope, precedence and rollback.

Set `hangar.missing_package_policy` to `"manual"` to require explicit installation.

`chadrc.lua` colors the active and inactive category tabs. Refer to the upstream guide for highlight groups.

## Registry and activation

`features.hangar.config` owns logical tool IDs, supported filetypes, backend aliases, installers and default order. Adapters translate logical IDs to backend names, such as `yaml` to Conform's `yamlfmt`.

Registry support lists do not change initial activation in `features.formatter.config` and `features.linter.config`. Re-enabling a tool uses those activation lists. For example, a tool can support Markdown but initially serve only web filetypes.

Set `tools.formatter_defaults` and `tools.linter_defaults` in personal settings to override initial priority. Valid saved order takes precedence.

Mark externally managed tools with `mason = nil` in the registry. Prepare their dependencies, such as debugpy, outside Mason.

## State and ownership

OrbitVim selects `stdpath('data')/hangar.json` as the state path. Set `vim.g.hangar_state_path` before setup to override it.

Hangar owns state persistence and the view lifecycle. See [architecture](architecture.md#hangar) for OrbitVim's composition of settings, registry and runtime adapters.
