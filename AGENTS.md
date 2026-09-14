# Repository guidance

## Project model

This repository is a personal Neovim configuration, not a general-purpose distribution. Prefer explicit declarative configuration and upstream plugin ownership over local framework layers.

The minimum supported Neovim version is `0.11.3`.

## Canonical ownership

`lua/config/tools.lua` is the canonical registry for development tools. Do not duplicate tool/filetype ownership in plugin specs when it can be derived.

`lua/config/packages.lua` derives:

- configured LSP server names
- Mason installation packages
- Treesitter parsers
- formatter routing by filetype
- linter routing by filetype

Runtime ownership is:

- Neovim `vim.lsp.config()` / `vim.lsp.enable()` for LSP activation
- Mason for supported external tool installation/status
- Conform for formatter routing/execution
- nvim-lint for linter routing/execution
- nvim-dap for debugger adapters/configurations
- nvim-treesitter for parsers

Do not reintroduce persisted tool enable/disable state, formatter/linter ordering state, or a parallel Tool Manager lifecycle unless there is a new requirement that cannot be represented declaratively.

## Module ownership

Keep formatter-specific code under `lua/config/formatter/` and linter-specific code under `lua/config/linter/`.

`lua/utils/sqlfluff.lua` owns SQLFluff project config/cwd/argument discovery.

`lua/utils/treesitter.lua` owns the custom T-SQL Tree-sitter runtime behavior. The SQL/C# query extensions under `after/queries/` are intentional project functionality.

Generic utility facades should not be added. Prefer owner-local helpers or direct Neovim/plugin public APIs for small behavior.

`utils.lsp`, `utils.cmp`, and `utils.window` contain higher-risk behavior. Change them deliberately and verify against the pinned plugin/Neovim APIs rather than deleting or rewriting them opportunistically.

## Startup and private APIs

Startup begins in `init.lua`, then `config.starter`.

Lazy.nvim bootstrap must fail fast when Git clone fails. Do not silently continue with an invalid runtime path.

Avoid new dependencies on private plugin internals. If an existing private API must be changed, verify the exact pinned revision in `lazy-lock.json` first.

## Platform behavior

Windows support is intentional. Shell executable selection must use capability checks such as `vim.fn.executable()` rather than architecture assumptions.

Preserve the Windows `ClearShada` safeguard in `lua/cmds/system.lua`. Do not broaden deletion behavior around shada files without a dedicated regression test.

## Lockfile policy

Keep `lazy-lock.json` unchanged unless a plugin version is intentionally updated or a plugin is intentionally added/removed. Do not regenerate the entire lockfile as incidental churn.

## Validation

Run `make all` for every behavioral change. It covers formatting checks, Luacheck, test-suite validation, and core tests.

Run `make test-integration` when changing external seams such as SQLFluff, Treesitter parser/query behavior, LSP integration, or other plugin/runtime integration points.

Run a headless startup smoke test when changing startup, plugin loading, shell/platform initialization, or core plugin specs:

```sh
nvim --headless "+qall"
```

CI validates Neovim `0.11.3` and stable. The stable lane also runs external integration/parser tests.

Core tests must remain deterministic and hermetic. Avoid network access and machine-specific state in `lua/test/spec/`.

When fixing a regression, add or update the closest focused test. In the final report explicitly state one of:

- `Tests added`
- `Tests updated`
- `No tests added`

## Change quality

Prefer small ownership surfaces and public APIs. Remove dead configuration when a feature is removed rather than leaving disabled code paths, stale statusline entries, commands, state files, or lockfile entries.

Keep commit history reviewable. For broad architecture refactors, group runtime/test changes separately from validation/documentation changes rather than producing many per-file commits.
