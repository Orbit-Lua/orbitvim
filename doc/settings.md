# Settings

`:OrbitSettings` or `<leader>uc` opens `settings.json` in the configuration directory. It creates the file only if it is absent. `:OrbitSettings reload` reads the saved input again. `:OrbitSettings info` shows active values, their sources, the last error and restart-pending changes. OrbitSettings never rewrites existing input, also when the file is invalid.

`settings.schema.json` owns keys, types, bounds, defaults and restart annotations. The loader supports the schema keywords that this schema uses. It validates tool, filetype and server references against the registry. It does not interpret arbitrary external schemas.

The command adds a `$schema` reference. jsonls also associates the exact settings path with the bundled schema, with normalized Windows drive letters. Thus an empty object also gets completion.

## Merge and precedence

Objects merge by field. Arrays replace previous arrays, also when they are empty. Boolean `false` is preserved. Removing a field restores its default. Unknown keys, wrong types, invalid ranges and typed null values reject the complete input before it applies. Server-specific `settings` accept arbitrary JSON.

`tools.formatter_defaults` and `tools.linter_defaults` set the initial filetype order. They use logical IDs such as `yaml`, not backend aliases such as `yamlfmt`. They override registry defaults at startup. Valid saved order in `tools.json` overrides both. Reload never changes saved enablement or order. Supported filetypes do not imply initial activation.

## Live updates

| Section | Application |
| --- | --- |
| `editor` | Changed fields update global defaults and normal loaded buffers/splits. Unchanged fields keep local overrides. Special buffers and floating windows keep their local options. Filetype plugins can customize new files. |
| `tool_manager` | Updates loaded options and refreshes the open view. Help and logical selection stay. |
| `lsp.inlay_hints` | Applies to supported attached clients and future attachments |
| `lsp.codelens`, `lsp.servers` | Needs a restart. Server settings merge into the Lua configuration. |
| `tools`, `notes` | Needs a restart. Persisted tool state keeps precedence. |

Automatic reload observes only writes to the configured file. It calls feature owners directly and does not change the plugin loading state. A repeated setup replaces its autocmd group.

Validation comes before each live update. When an application fails, it restores the captured values and keeps the accepted settings snapshot. Inlay hints handle their own rollback. If restoration fails, the error reports both failures and asks for a restart. Restart-only values stay active until startup, also when new values are saved.

Invalid startup settings show a warning and fall back to defaults. Thus the editor stays available for repair.

## Ownership

Change public defaults in the schema. Change available tools in `config.tools`.

- `config.settings` decodes and validates detached values.
- `core.settings` owns application, rollback and save observation.
- `commands.settings` owns commands and information views.
- `runtime.lsp` owns inlay hints.
- `tool.state` merges initial priorities before saved state.
