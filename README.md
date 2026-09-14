# nvim-config

[![Validate](https://github.com/gin31259461/nvim-config/actions/workflows/validate.yml/badge.svg)](https://github.com/gin31259461/nvim-config/actions/workflows/validate.yml)
[![Neovim 0.11.3+](https://img.shields.io/badge/Neovim-0.11.3%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)

A personal Neovim configuration with a small, declarative runtime surface.
It keeps tool metadata in one registry and delegates installation, language
servers, formatting, linting, debugging, and parsing to their owning tools.

## Requirements

- Neovim 0.11.3 or newer
- Git
- A Nerd Font
- luacheck on PATH for Lua linting (1.2.x recommended)
- Project-specific runtimes such as .NET, Node.js, Python, or a C compiler

Plugin revisions are pinned in [lazy-lock.json](lazy-lock.json). CI validates
Neovim 0.11.3 and the current stable release.

## Install

Back up an existing configuration, then clone this repository to your Neovim
configuration directory:

```sh
git clone https://github.com/gin31259461/nvim-config.git ~/.config/nvim
nvim
```

On Windows, use the directory returned by :echo stdpath('config').

The first startup bootstraps the exact lazy.nvim revision pinned in the
lockfile. Clone or checkout failures stop startup immediately.

## Configuration model

[lua/config/tools.lua](lua/config/tools.lua) is the canonical registry for
LSP servers, DAP adapters, formatters, linters, Treesitter parsers, and their
installer dependencies. [lua/config/packages.lua](lua/config/packages.lua)
derives the consumer-specific lists and filetype routing from that registry.

Runtime ownership is deliberately explicit:

| Concern | Owner |
| --- | --- |
| LSP activation | Neovim vim.lsp.config() / vim.lsp.enable() |
| External tool installation | Mason |
| Formatting | Conform |
| Linting | nvim-lint |
| Debugging | nvim-dap |
| Parsing | nvim-treesitter |

Formatter code belongs under lua/config/formatter/; linter code belongs under
lua/config/linter/. SQLFluff project discovery is in
lua/utils/sqlfluff.lua, and custom T-SQL behavior is in lua/utils/treesitter.lua
with query extensions under after/queries/.

## Useful mappings

| Mapping | Action |
| --- | --- |
| `<leader>fm` | Format the current buffer |
| `<leader>fd` | Change directory to the current project root |
| `<leader>tf` | Open a diagnostic float |
| `<leader>h` / `<leader>v` | Open a horizontal / vertical terminal |
| `<M-h>` / `<M-v>` / `<M-i>` | Toggle terminals |
| `<C-n>` | Toggle nvim-tree |
| `<leader>fe` | Focus nvim-tree |
| `<Tab>` / `<S-Tab>` | Next / previous buffer |

## Development

Run the default validation locally:

```sh
make all
```

This runs formatting checks, Luacheck, suite validation, and the hermetic
core and general test suites.

External integration tests are optional and require parser/tool setup:

```sh
nvim --headless -u init.lua -l lua/test/install_parsers.lua
make test-integration
```

Run every suite with make test-all. Use scripts/tests/minimal.vim for focused
Plenary runs.

## Layout

```text
init.lua                     pinned lazy.nvim bootstrap
lua/config/tools.lua         canonical tool registry
lua/config/packages.lua      derived consumer configuration
lua/config/formatter/        Conform configuration and runtime
lua/config/linter/           nvim-lint configuration and runtime
lua/plugins/                 plugin specifications
lua/utils/                   owner-local utilities
lua/test/core/               hermetic core tests
lua/test/general/            hermetic general tests
lua/test/integration/        optional external integration tests
after/queries/               Treesitter query extensions
doc/                         T-SQL documentation
.github/workflows/           CI validation
```

Windows support is intentional, including the ClearShada safeguard in
lua/cmds/system.lua.
