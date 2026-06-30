# OrbitVim

OrbitVim is a personal Neovim configuration based on [NvChad](https://github.com/NvChad/NvChad).
It keeps the Nv UI and base46 pieces that are still useful through the
`Orbit-Lua/nv-ui` and `Orbit-Lua/nv-base46` forks, then layers a practical
LSP-first workflow, managed formatter and linter tooling, Python and .NET
debugging, Git navigation, project search, and Copilot-assisted editing.

It is designed for daily development across Lua, Python, TypeScript,
JavaScript, C#, Go, shell, Markdown, SQL, Docker, TOML, JSON, XML, and Prisma
projects.

## Features

- Nv UI/base46 theming kept as explicit local dependencies
- One service registry for LSP servers, DAP adapters, formatters, and linters
- Service Manager UI for enabling tools, installing Mason packages, and
  reordering formatter or linter priority by filetype
- Manual formatting by default, so saves do not unexpectedly rewrite buffers
- Cross-platform behavior with Windows-specific fixes where needed
- Headless Plenary tests for shared utilities and Service Manager logic

## Requirements

Required for normal use:

- Neovim 0.12+
- Git
- A Nerd Font, preferably a non-Mono variant
- `ripgrep` for project search
- `tree-sitter-cli` for Treesitter parser management

Optional tools enable specific features:

- `lazygit` for `<leader>gg`
- Node.js and npm for Node-based tools and plugin builds
- `pnpm` for `markdown-preview.nvim`
- `dotnet` for Roslyn, .NET helpers, and .NET debugging
- `debugpy` inside the active Python virtual environment for Python debugging
- `stylua`, `luacheck`, and synced plugins for repository validation

## Install

Back up any existing Neovim configuration first.

Linux and macOS:

```bash
git clone https://github.com/gin31259461/orbitvim.git ~/.config/nvim
nvim
```

Windows:

```powershell
winget install --id=Neovim.Neovim -e
winget install --id=JesseDuffield.lazygit -e
npm install -g pnpm
git clone https://github.com/gin31259461/orbitvim.git $env:LOCALAPPDATA\nvim
nvim
```

For native plugin compilation on Windows, install MSYS2 and MinGW:

```powershell
winget install --id=MSYS2.MSYS2 -e
```

Then install the toolchain from an MSYS2 MinGW64 shell:

```bash
pacman -Sy mingw-w64-x86_64-gcc mingw-w64-x86_64-toolchain
```

Add `C:\msys64\mingw64\bin` to `PATH`.

## First Run

`init.lua` bootstraps `lazy.nvim` automatically. On the first launch, wait for
Lazy to finish installing plugins, then run:

```vim
:MasonInstallAll
:TSInstallAll
```

Restart Neovim after Mason and Treesitter finish.

`:MasonInstallAll` installs Mason-managed tools derived from
`lua/config/services.lua` and `lua/config/packages.lua`. It does not install
project-local dependencies such as Python `debugpy` or Prisma packages in
`node_modules`.

Recommended follow-up setup:

- Run `:Copilot auth` before using Copilot suggestions
- Install `debugpy` in each Python virtual environment that needs debugging
- Install project-local Node dependencies before using Prisma formatting
- Run `:Lazy sync` if plugin state is missing or tests cannot load
  `plenary.nvim`

## Core Features

Editing and navigation:

- Snacks dashboard, picker, notifications, quickfile, bigfile, scroll, and
  image support
- `nvim-tree` file explorer with Git and diagnostic highlights
- Telescope for command-driven pickers
- Harpoon for fast project file jumps
- Local terminal manager for horizontal, vertical, and floating terminals

Language tooling:

- LSP setup through Neovim LSP, `nvim-lspconfig`, Mason, Roslyn, and
  TypeScript Tools
- Completion through `nvim-cmp`, LuaSnip, autopairs, and lazydev
- Treesitter parser install command through `:TSInstallAll`
- Diagnostics, inlay hints, code actions, rename, hover, and signature help

Formatting and linting:

- `conform.nvim` for manual formatting through `<leader>fm`
- `nvim-lint` for linting on read, write, and new-file events
- Service-aware formatter and linter filtering
- Per-filetype formatter and linter priority managed through Service Manager

Debugging:

- Python debugging through `debugpy` from the active virtual environment
- .NET debugging through `netcoredbg`
- DAP UI, REPL, watches, breakpoints, stepping, and restart mappings

UI and theme:

- `Orbit-Lua/nv-ui` and `Orbit-Lua/nv-base46` for statusline, tabline,
  dashboard, theme highlights, and base46 integrations
- Local theme picker through `<leader>th`
- Theme persistence by updating `lua/config/nvui.lua`
- Local highlight overrides through `hl_override` and `hl_add`

## Service Manager

Open Service Manager with `<leader>sm` or `:ServiceManager` after Lazy has
finished loading. The command is registered on `User LazyDone`, so it is not
available during early startup.

Service Manager reads `lua/config/services.lua` and can:

- Enable or disable registered LSP servers, formatters, linters, and DAP
  adapters
- Install missing Mason-backed tools
- Reorder formatter and linter priority per filetype
- Inspect service details, install state, diagnostics, and runtime errors

State is stored outside this repository in Neovim's data directory as
`service.json`, so each machine can have different enabled tools and ordering.
Enabling a missing Mason-backed service can auto-install its package because
the missing package policy is `auto`.

Inside the UI:

- `<Space>` toggles a service
- `<CR>`, `o`, or `za` expands details
- `i` installs a tool
- `[` and `]` reorder formatter or linter priority
- `<Tab>` and `<S-Tab>` switch category tabs
- `K` shows a tooltip
- `g?` toggles help
- `q` closes the window

## Daily Workflow

Leader is `<Space>`. Use `<leader>wK` or `<leader>sk` to inspect all keymaps.

Common mappings:

- `<C-s>` saves the current file
- `<leader>fm` formats the current file or selection
- `<leader>ff`, `<leader>fg`, `<leader>sg`, and `<leader>sw` search files,
  Git files, project text, and the current word or visual selection
- `<leader>fb` lists buffers
- `<leader>gg` opens lazygit
- `<leader>sm` opens Service Manager
- `<leader>dp` opens the .NET manager
- `<leader>th` opens the theme picker
- `<C-n>` toggles nvim-tree and `<leader>e` focuses it
- `<C-e>` opens Harpoon, `<leader>ba` adds a file, and `<M-S-p>` /
  `<M-S-n>` move through Harpoon entries
- `<leader>h`, `<leader>v`, `<M-h>`, `<M-v>`, and `<M-i>` create or toggle
  terminals

## Project Layout

```text
init.lua                 lazy.nvim bootstrap and starter entrypoint
lua/config/starter.lua   startup orchestration after lazy.nvim setup
lua/nvconfig.lua         local nv-ui/nv-base46 config entrypoint
lua/config/nvui.lua      Nv UI, base46, Mason, statusline, tabline, theme,
                         highlight, and terminal settings
lua/config/theme.lua     local base46 theme picker and persistence
lua/config/services.lua  canonical managed-tool registry
lua/config/packages.lua  Mason and LSP package derivation from services
lua/plugins/             lazy.nvim plugin specs grouped by feature area
lua/service/             Service Manager UI, actions, renderer, state, order
lua/cmds/                custom commands loaded during startup
lua/utils/               shared Lua helpers
lua/test/spec/           Plenary test suite
scripts/tests/           headless test bootstrap
```

`lua/plugins/init.lua` is intentionally empty. Lazy imports the `plugins`
namespace and discovers the feature-specific spec files directly.

## Managed Tooling

`lua/config/services.lua` is the source of truth for managed services.
`lua/config/packages.lua` derives Mason packages and LSP server names from that
registry.

Use the service registry when adding or removing managed:

- LSP servers
- DAP adapters
- formatters
- linters
- default formatter or linter order

Mason does not cover every runtime dependency. Python DAP needs `debugpy` in
the active environment, .NET support needs `dotnet`, and Prisma formatting
expects project-local Node dependencies.

## Development

Validation commands:

```bash
make all   # format lua/, lint lua/, and run headless Plenary tests
make fmt   # format lua/ with stylua
make lint  # lint lua/ with luacheck
make test  # run headless Plenary tests
```

`make test` uses `scripts/tests/minimal.vim` and loads `plenary.nvim` from
Neovim's lazy data directory. If tests cannot load plugins, run `:Lazy sync`
inside Neovim and retry.

For changes to `init.lua`, `lua/config/starter.lua`, or other startup paths,
also run:

```bash
nvim --headless "+qall"
```

## Troubleshooting

- `:ServiceManager` is unavailable right after launch: wait for Lazy to finish
  loading, then retry `<leader>sm` or `:ServiceManager`.
- `make test` cannot load Plenary: run `:Lazy sync` and retry after
  `plenary.nvim` exists in the lazy data directory.
- Python debugging fails: activate the project virtual environment and install
  `debugpy` there.
- Prisma formatting fails: install the project's Node dependencies so Prisma
  exists in `node_modules`.
- .NET support does not load: verify `dotnet` is available on `PATH`.
- Markdown preview fails to build: verify Node.js, npm, and pnpm are available.
- Windows ShaDa temp files get stuck: use `:ClearShada`, which keeps
  `main.shada` and removes temporary ShaDa files.

## Runtime Notes

- Formatting is manual; format-on-save is disabled.
- Service Manager state lives outside the repo as `service.json`.
- The base46 cache lives under Neovim's data directory at `nvchad/base46`.
- Obsidian integration only loads when `~/OneDrive/Knowledge_Base` exists.
- `nvim <dir>` changes cwd to that directory and removes the initial empty
  buffer.
