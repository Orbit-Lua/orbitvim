# Settings

`:OrbitSettings` and `<leader>uc` open `settings.json` in Neovim's configuration directory. `:OrbitSettings reload` loads the saved file; `:OrbitSettings info` opens a read-only view of active values, their sources, the last error and pending restart changes. A missing file uses defaults and is created only when opened through the command. An existing file is preserved, including invalid contents.

`settings.schema.json` defines supported keys, types, bounds, descriptions, restart annotations and defaults. JSON language servers use its `$schema` reference for completion and validation. The loader interprets the keywords used by this bundled schema; it is not a validator for arbitrary external schemas. It also validates tool IDs, supported filetypes and LSP server IDs against the canonical registry.

OrbitVim also associates the configured file path with this schema in `jsonls`, so completion still works when the file contains only `{}`. Windows drive letters are normalized to the JSON service's matching convention. Other editors can use the `$schema` reference created by the command.

## Merge and precedence

Objects merge by field. Arrays replace the previous array, including an empty array. `false` remains a boolean override. Removing a field restores its default. Unknown fields, wrong types, invalid ranges and null values in typed fields reject the entire input before changes are applied. Server-specific `settings` may contain arbitrary JSON values.

`tools.formatter_defaults` and `tools.linter_defaults` specify initial priority lists by filetype, using logical IDs such as `yaml`, rather than backend aliases such as `yamlfmt`. Built-in priorities come from `config.tools`; user defaults override them on startup. Valid saved order in the data directory's `tools.json` takes precedence. Reloading user settings never writes tool enablement or saved order. Supported filetypes continue to be distinct from initial runtime activation.

## Live updates

| Section | Effect |
| --- | --- |
| `editor` | Applies changed fields to global defaults, loaded normal buffers and normal editing splits. Unchanged fields retain local overrides. Special buffers retain their buffer options; floating windows retain their window options. Filetype plugins may apply their own values to subsequently opened files. |
| `tool_manager` | Updates the loaded options table and refreshes the open session, retaining help and logical selection. |
| `lsp.inlay_hints` | Updates attached clients that support inlay hints and the policy used for future attachments. |
| `lsp.codelens`, `lsp.servers` | Requires a restart. Server settings merge into the existing Lua server options. |
| `tools` | Requires a restart. Saved tool state retains precedence. |

Only a write to the configured settings path triggers automatic reload. Reload calls feature owners directly and preserves plugin loading state. Repeat setup replaces the same autocmd group.

The whole file is decoded and validated first. Live option changes capture previous values; an apply error restores those values and leaves the accepted settings unchanged. Inlay hint updates perform their own rollback. A rollback failure reports both errors and requests a restart because runtime values may differ from the accepted snapshot. Restart-only sections retain their active values until the next startup; they can be saved alongside live changes. Invalid startup input warns and uses defaults so the settings command remains available for repair.

## Ownership

`config.settings` reads the schema, resolves overrides, validates registry references and stores detached accepted values. `core.settings` owns editor application, save observation, rollback and effective-value reporting. `commands.settings` owns command registration and the settings/info views. `runtime.lsp` owns inlay hint changes. `tool.state` merges initial priorities before loading saved tool state.

Changes to defaults belong in the schema; changes to available tools belong in `config.tools`. Lua filenames use `snake_case`; configuration assembly entry points use `init.lua`. Plugin identities, user commands, mappings and persisted logical IDs retain their external names.
