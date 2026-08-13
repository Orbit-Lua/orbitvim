# OrbitVim

[![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io/)
[![Lua](https://img.shields.io/badge/Lua-config-2C2D72?style=flat-square&logo=lua&logoColor=white)](https://www.lua.org/)
[![lazy.nvim](https://img.shields.io/badge/plugins-lazy.nvim-blue?style=flat-square)](https://github.com/folke/lazy.nvim)

OrbitVim is a modular Neovim configuration built around
[lazy.nvim](https://github.com/folke/lazy.nvim), NvChad-style UI components,
Mason-managed language tooling, and a custom Tool Manager for LSP, DAP,
formatter, linter, Treesitter parser, and package dependency control.

It is aimed at day-to-day editing across Lua, Python, C#, TypeScript,
JavaScript, web files, shell, Markdown, SQL, Docker, XML, Go, TOML, and Prisma.

## Features

- Fast lazy-loaded plugin setup with `lazy.nvim`
- Nv UI/base46 theme integration with local theme persistence
- Managed LSP registry derived from one tool configuration file
- Tool Manager UI for enabling, disabling, installing, inspecting, and
  ordering language tools, parsers, and package dependencies
- Formatting through `conform.nvim` and linting through `nvim-lint`
- DAP support for Python and .NET
- Treesitter parsers and editor helpers for common languages
- Navigation with `nvim-tree`, Snacks, and Harpoon
- Completion with `blink.cmp`, LuaSnip, lazydev, and local Minuet AI suggestions
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
- For AI completion: Ollama serving `qwen2.5-coder:7b-base-q6_K` locally or
  through a private Tailscale connection. See the
  [Arch Linux setup guide](doc/ollama.md).

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
`lua/config/tools.lua` and `lua/config/packages.lua`.

After plugins are installed, install Treesitter parsers from inside Neovim:

```vim
:TSInstallAll
```

## Usage

Open the Tool Manager:

```vim
:ToolManager
```

Common mappings:

| Mapping | Action |
| --- | --- |
| `<leader>us` | Open Tool Manager |
| `<leader>ut` | Open nv-ui's theme picker and persist the selected theme |
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

Tool Manager keys:

| Key | Action |
| --- | --- |
| `1`-`6` | Switch tool category |
| `<Tab>` / `<S-Tab>` | Move between categories |
| `<Space>` | Enable or disable supported runtime tools |
| `i` | Install a Mason package or Treesitter parser |
| `[` / `]` | Reorder formatter or linter priority |
| `K` | Show tool tooltip |
| `o`, `<CR>`, `za` | Expand or collapse a group |
| `g?` | Toggle help |
| `q`, `<Esc>` | Close |

### AI completion endpoint

Minuet uses the local Ollama endpoint by default. Open the endpoint picker, or
select a host directly:

```vim
:MinuetEndpoint
:MinuetEndpoint 100.64.0.8
:MinuetEndpoint https://workstation.example.ts.net
```

An IP or hostname without a scheme uses
`http://<host>:11434/v1/completions`. An HTTPS URL without a port uses port 443,
which is suitable for Tailscale Serve. The selected endpoint and endpoint
history are stored in Neovim's data directory as `minuet-endpoints.json`; the
runtime Minuet configuration is updated immediately.

Use `:MinuetEndpoint!` to remove a saved remote endpoint. The local
`127.0.0.1:11434` fallback is always retained.

For Ollama installation, Vulkan configuration, model setup, and private
Tailscale access, follow the [Arch Linux Ollama guide](doc/ollama.md).

### SQL dialects

SQLFluff defaults to T-SQL and uses a DataGrip-like layout profile when a
project does not provide its own SQLFluff configuration. Select another dialect
for one file with a first-line SQLFluff directive:

```sql
-- sqlfluff:dialect:postgres

SELECT payload::JSONB
FROM events;
```

Project-local `.sqlfluff`, `pyproject.toml`, `setup.cfg`, `tox.ini`, and
`pep8.ini` files take precedence over OrbitVim's fallback profile. Put ignored
paths in a project-root `.sqlfluffignore`; a starter template is available at
`lua/config/db/template/.sqlfluffignore`.

### T-SQL snippets

SQL buffers use the convention-based LuaSnip collection in
`luasnippets/tsql.lua`; the generic SQL snippets from `friendly-snippets` are
disabled. Type a trigger, accept it from the completion menu with `<CR>` or
`<C-y>`, then move through placeholders with `<Tab>` and `<S-Tab>`.

Representative triggers include:

| Area | Triggers |
| --- | --- |
| Objects | `ctable`, `cview`, `cprocr`, `cprocw`, `cfunc`, `citvf`, `ctrig` |
| Queries | `sel`, `seltop`, `selpage`, `cte`, `rowpart`, `exists`, `nexists` |
| DML | `ins`, `inso`, `upd`, `updo`, `del`, `delo`, `upsert` |
| Reliability | `txn`, `trycatch`, `throw`, `dynsql`, `dynident` |
| Schema | `idx`, `idxinc`, `fk`, `checkcon`, `defaultcon`, `utccol` |

The collection follows the [T-SQL conventions](doc/tsql-conventions.md),
including explicit schemas and columns, named constraints, semicolon
termination, UTC timestamps, `CREATE OR ALTER`, transaction ownership, and
parameterized dynamic SQL. See the
[complete T-SQL snippet guide](doc/tsql-snippets.md) for every trigger, safety
notes, and maintenance instructions.

## Project Layout

```text
.
├── init.lua                  # lazy.nvim bootstrap and startup entrypoint
├── lua/config/               # editor options, keymaps, UI, tools, packages
├── lua/plugins/              # lazy.nvim plugin specs grouped by feature area
├── lua/tool/                 # Tool Manager state, adapters, UI, and data
├── lua/utils/                # shared helpers
├── lua/cmds/                 # custom commands loaded at startup
├── lua/test/spec/            # Plenary test specs
├── luasnippets/              # local LuaSnip collections by snippet filetype
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
  -c "PlenaryBustedFile lua/test/spec/tool_state_spec.lua {minimal_init = 'scripts/tests/minimal.vim'}"
```

## Configuration Notes

- `lua/config/tools.lua` is the source of truth for managed LSP, DAP,
  formatter, linter, parser, and dependency tools.
- `lua/config/packages.lua` derives Mason package lists, LSP server lists, and
  Treesitter parser lists.
- `lua/chadrc.lua` owns Nv UI/base46 settings, highlights, Mason package config,
  statusline, tabline, terminal settings, and the theme persisted by nv-ui's
  built-in picker.
- Tool Manager state is stored in Neovim's data directory as `tools.json`
  unless `vim.g.tool_state_path` is overridden. Existing `service.json` state
  is read as a migration fallback.
- Minuet endpoint state is stored in Neovim's data directory as
  `minuet-endpoints.json`; it contains endpoint URLs only, not credentials.

> [!TIP]
> When adding or removing language tooling, start in `lua/config/tools.lua`
> and let the package derivation tests tell you what else needs to change.
