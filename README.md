# nvim-config

Personal Neovim configuration with a small, declarative runtime surface.

The configuration intentionally avoids maintaining a second plugin/tool lifecycle layer. Tool ownership is explicit: Mason installs supported external tools, Neovim owns LSP activation, Conform owns formatting, nvim-lint owns linting, nvim-dap owns debugger adapters, and nvim-treesitter owns parsers.

## Requirements

- Neovim `0.11.3+`
- Git
- A Nerd Font
- `luacheck` on `PATH` for Lua linting (`1.2.x` recommended)
- Language/runtime dependencies required by the projects you edit, such as `dotnet`, Node.js, Python, or a C compiler

The lockfile pins plugin revisions. CI validates both Neovim `0.11.3` and the current stable release.

## Installation

Back up any existing configuration, then clone this repository as your Neovim config:

```sh
git clone https://github.com/gin31259461/nvim-config.git ~/.config/nvim
nvim
```

On Windows, clone it to the directory returned by `:echo stdpath('config')`.

`init.lua` bootstraps the exact lazy.nvim revision pinned by `lazy-lock.json` and fails immediately if Git clone or checkout cannot complete.

## Architecture

`lua/config/tools.lua` is the canonical development-tool registry. It declares LSP servers, DAP adapters, linters, formatters, Treesitter parsers, and installer dependencies. `lua/config/packages.lua` derives consumer-specific structures from that registry:

- `lsp_servers`
- `mason_ensure_installed`
- `treesitter_ensure_installed`
- `formatters_by_ft`
- `linters_by_ft`

There is no persistent tool enable/disable state. Runtime routing is deterministic and checked into Lua configuration.

Formatter ownership lives under `lua/config/formatter/`; linter ownership lives under `lua/config/linter/`. SQLFluff project discovery is implemented in `lua/utils/sqlfluff.lua`. T-SQL Tree-sitter behavior is implemented in `lua/utils/treesitter.lua` and the query files under `after/queries/`.

The former Tool Manager and dormant Minuet/Ollama subsystem were removed. Terminal windows use Snacks' public terminal API.

## Selected mappings

| Mapping | Action |
| --- | --- |
| `<leader>fm` | Format current buffer |
| `<leader>fd` | Set cwd to the current file/project root |
| `<leader>tf` | Open diagnostic float |
| `<leader>h` | Open a new horizontal terminal |
| `<leader>v` | Open a new vertical terminal |
| `<M-h>` | Toggle horizontal terminal |
| `<M-v>` | Toggle vertical terminal |
| `<M-i>` | Toggle floating terminal |
| `<C-n>` | Toggle nvim-tree |
| `<leader>fe` | Focus nvim-tree |
| `<Tab>` / `<S-Tab>` | Next / previous buffer in native buffer order |

## Development

Core validation:

```sh
make all
```

This runs StyLua check, Luacheck, suite validation, and core tests.

External integration tests:

```sh
make test-integration
```

Run everything locally with:

```sh
make test-all
```

Focused tests can be run through Plenary using `scripts/tests/minimal.vim`. Important regression coverage includes registry derivation, formatter async state, SQLFluff routing, per-buffer lint debounce, and filesystem path-boundary handling.

## Project layout

```text
init.lua                     pinned lazy.nvim bootstrap
lua/config/tools.lua         canonical tool registry
lua/config/packages.lua      derived consumer configuration
lua/config/formatter/        Conform configuration/runtime
lua/config/linter/           nvim-lint configuration/runtime
lua/plugins/lsp/             LSP policy and server configuration
lua/plugins/debugger/        nvim-dap adapters/configurations
lua/utils/                   domain-specific helpers only
lua/test/spec/               hermetic/core tests
lua/test/integration/        external integration tests
after/queries/               Tree-sitter query extensions
doc/                         T-SQL documentation
.github/workflows/            validation contract
```

## Design rules

Prefer plugin public APIs over private internals. Add project-specific policy only when upstream ownership is insufficient. Keep one canonical source for tool metadata and derive consumer maps rather than duplicating filetype lists. Avoid persisted runtime state for settings already represented by version-controlled Lua.

Windows-specific `ClearShada` safety behavior is intentionally retained.
