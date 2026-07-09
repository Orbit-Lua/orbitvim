# OrbitVim

[![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io/)
[![Lua](https://img.shields.io/badge/Lua-config-2C2D72?style=flat-square&logo=lua&logoColor=white)](https://www.lua.org/)
[![lazy.nvim](https://img.shields.io/badge/plugins-lazy.nvim-blue?style=flat-square)](https://github.com/folke/lazy.nvim)

OrbitVim is a modular Neovim configuration built around
[lazy.nvim](https://github.com/folke/lazy.nvim), NvChad-style UI components,
Mason-managed language tooling, and a custom Service Manager for LSP, DAP,
formatter, and linter control.

It is aimed at day-to-day editing across Lua, Python, C#, TypeScript,
JavaScript, web files, shell, Markdown, SQL, Docker, XML, Go, TOML, and Prisma.

## Features

- Fast lazy-loaded plugin setup with `lazy.nvim`
- Nv UI/base46 theme integration with local theme persistence
- Managed LSP registry derived from one service configuration file
- Service Manager UI for enabling, disabling, installing, inspecting, and
  ordering language services
- Formatting through `conform.nvim` and linting through `nvim-lint`
- DAP support for Python and .NET
- Treesitter parsers and editor helpers for common languages
- Navigation with `nvim-tree`, Snacks, and Harpoon
- Completion with `blink.cmp`, LuaSnip, lazydev, and optional Copilot integration
- Markdown preview, diagnostics UI, Noice notifications, Trouble, which-key, and
  Git signs

## Requirements

- Neovim 0.10 or newer
- Git
- Make
- `stylua`
- `luacheck`
- A C compiler and runtime tools required by Neovim plugins on your platform
- Optional language runtimes for the stacks you use: Node.js, Python, .NET, Go,
  Deno, PowerShell, Docker tools, and SQL tooling

> [!NOTE]
> The configuration prepends Mason's `bin` directory to `PATH` during startup,
> but repository validation commands still expect `stylua` and `luacheck` to be
> available from the shell that runs `make`.

## Installation

Clone the repository as your Neovim config:

```bash
git clone git@github.com:Orbit-Lua/orbitvim.git ~/.config/nvim
```

Start Neovim:

```bash
nvim
```

On first launch, `init.lua` bootstraps `lazy.nvim` into Neovim's data directory
and installs configured plugins. Mason packages are derived from
`lua/config/services.lua` and `lua/config/packages.lua`.

After plugins are installed, install Treesitter parsers from inside Neovim:

```vim
:TSInstallAll
```

## Usage

Open the Service Manager:

```vim
:ServiceManager
```

Common mappings:

| Mapping | Action |
| --- | --- |
| `<leader>sm` | Open Service Manager |
| `<leader>th` | Open theme picker and persist the selected base46 theme |
| `<leader>fm` | Format current buffer |
| `<leader>fd` | Open diagnostics float |
| `<C-n>` | Toggle file tree |
| `<leader>e` | Focus file tree |
| `<C-e>` | Toggle Harpoon menu |
| `<leader>mp` | Toggle Markdown preview |
| `<leader>dt` | Toggle DAP breakpoint |
| `<leader>du` | Toggle DAP UI |
| `<M-i>` | Toggle floating terminal |
| `<M-h>` | Toggle horizontal terminal |
| `<M-v>` | Toggle vertical terminal |

Service Manager keys:

| Key | Action |
| --- | --- |
| `1`-`4` | Switch service category |
| `<Tab>` / `<S-Tab>` | Move between categories |
| `<Space>` | Enable or disable service |
| `i` | Install Mason-backed service package |
| `[` / `]` | Reorder formatter or linter priority |
| `K` | Show service tooltip |
| `o`, `<CR>`, `za` | Expand or collapse a group |
| `g?` | Toggle help |
| `q`, `<Esc>` | Close |

## Project Layout

```text
.
├── init.lua                  # lazy.nvim bootstrap and startup entrypoint
├── lua/config/               # editor options, keymaps, UI, services, packages
├── lua/plugins/              # lazy.nvim plugin specs grouped by feature area
├── lua/service/              # Service Manager state, rendering, actions, data
├── lua/utils/                # shared helpers
├── lua/cmds/                 # custom commands loaded at startup
├── lua/test/spec/            # Plenary test specs
└── scripts/tests/minimal.vim # headless test bootstrap
```

## Development

Run the full local check:

```bash
make all
```

That runs:

```bash
make fmt
make lint
make test
```

For startup-path changes, also run:

```bash
nvim --headless "+qall"
```

Run a focused Plenary spec with:

```bash
nvim --headless --noplugin -u scripts/tests/minimal.vim \
  -c "PlenaryBustedFile lua/test/spec/service_state_spec.lua {minimal_init = 'scripts/tests/minimal.vim'}"
```

## Configuration Notes

- `lua/config/services.lua` is the source of truth for managed LSP, DAP,
  formatter, and linter services.
- `lua/config/packages.lua` derives Mason package lists, LSP server lists, and
  Treesitter parser lists.
- `lua/config/nvui.lua` owns Nv UI/base46 settings, highlights, Mason package
  config, statusline, tabline, and terminal settings.
- `lua/config/theme.lua` updates the selected theme in `lua/config/nvui.lua`.
- Service Manager state is stored in Neovim's data directory as `service.json`
  unless `vim.g.service_state_path` is overridden.

> [!TIP]
> When adding or removing language tooling, start in `lua/config/services.lua`
> and let the package derivation tests tell you what else needs to change.
