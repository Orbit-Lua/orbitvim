# Settings

`:OrbitSettings` or `<leader>uc` opens the configuration directory's `settings.json`, creating it only if absent. `:OrbitSettings reload` rereads saved input. `:OrbitSettings info` shows active values, their sources, the last error and restart-pending changes. Existing input is never rewritten, including invalid files.

`settings.schema.json` owns keys, types, bounds, defaults and restart annotations. The loader supports the schema keywords used here and validates tool, filetype and server references against the registry. It does not interpret arbitrary external schemas.

The command adds a `$schema` reference. jsonls also associates the exact settings path with the bundled schema, including normalized Windows drive letters, so an empty object still receives completion.

## Merge and precedence

Objects merge by field; arrays replace previous arrays, including when empty. Boolean `false` is preserved. Removing a field restores its default. Unknown keys, wrong types, invalid ranges and typed null values reject the complete input before application. Server-specific `settings` accept arbitrary JSON.

`tools.formatter_defaults` and `tools.linter_defaults` set initial filetype order using logical IDs such as `yaml`, not backend aliases such as `yamlfmt`. They override registry defaults at startup; valid saved order in `tools.json` overrides both. Reload never changes saved enablement or order. Supported filetypes do not imply initial activation.

## Live updates

| Section | Application |
| --- | --- |
| `editor` | Changed fields update global defaults and normal loaded buffers/splits. Unchanged fields keep local overrides; special buffers and floating windows keep their local options. Filetype plugins may customize new files. |
| `tool_manager` | Update loaded options and refresh the open view while preserving help and logical selection |
| `lsp.inlay_hints` | Apply to supported attached clients and future attachments |
| `lsp.codelens`, `lsp.servers` | Restart required; server settings merge into Lua configuration |
| `tools`, `notes` | Restart required; persisted tool state keeps precedence |

Automatic reload observes only writes to the configured file. It calls feature owners directly without changing plugin loading state; repeated setup replaces its autocmd group.

Validation precedes every live update. Application failures restore captured values and keep the accepted settings snapshot. Inlay hints handle their own rollback. If restoration fails, the error reports both failures and requests a restart. Restart-only values remain active until startup even when new values are saved.

Invalid startup settings warn and fall back to defaults so the editor remains available for repair.

## Ownership

Change public defaults in the schema and available tools in `config.tools`. `config.settings` decodes and validates detached values; `core.settings` owns application, rollback and save observation. `commands.settings` owns commands and information views, `runtime.lsp` owns inlay hints, and `tool.state` merges initial priorities before saved state.
