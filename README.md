# OrbitVim

[![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io/)
[![Lua](https://img.shields.io/badge/Lua-config-2C2D72?style=flat-square&logo=lua&logoColor=white)](https://www.lua.org/)
[![lazy.nvim](https://img.shields.io/badge/plugins-lazy.nvim-blue?style=flat-square)](https://github.com/folke/lazy.nvim)

OrbitVim is a modular, high-performance Neovim configuration built around
[lazy.nvim](https://github.com/folke/lazy.nvim), Nv UI/base46 aesthetics,
Mason-managed language tooling, and a custom interactive Tool Manager for LSP,
DAP, formatters, linters, Treesitter parsers, and package dependencies.

It provides a cohesive, reproducible development environment tailored for
C#, Python, TypeScript, JavaScript, Go, SQL (T-SQL/PostgreSQL), web files,
Markdown, Docker, and shell scripting.

---

## Features

- **Predictable 3-Phase Startup**: Clean separation between Pre-Lazy environment/options,
  Lazy plugin management, and Post-Lazy runtime configuration.
- **Pure Plugin Specifications**: `lua/plugins/` contains strictly declarative `LazySpec`
  tables, while domain logic (LSP, DAP, formatters, linters) resides in dedicated `lua/config/` domains.
- **Unified Tool Manager**: Interactive UI (`:ToolManager` / `<leader>us`) to inspect,
  toggle, install, and reorder formatters, linters, LSP servers, DAP adapters, and parsers.
- **Single Source of Truth**: `lua/config/tools.lua` canonically defines all language tooling;
  Mason packages, LSP servers, and Treesitter parsers are automatically derived.
- **Nv UI & Base46 Theme Integration**: Beautiful themes with compile-cached highlights
  and persistent runtime switching (`<leader>ut`).
- **Modern Completion & AI**: Fast snippet and symbol completion via `blink.cmp`, paired
  with local or remote Ollama code completion via `minuet-ai`.
- **Full Debugging (DAP)**: Pre-configured debugging adapters and launch profiles for
  .NET (C#) and Python.
- **Database & SQL Tooling**: Advanced T-SQL Treesitter queries, C# SQL string injections,
  DataGrip-compatible SQLFluff formatting, and specialized T-SQL snippets.

---

## Architecture & Lifecycle

OrbitVim organizes execution into three deterministic lifecycle phases in `init.lua`:

```
init.lua (Unified Startup Lifecycle)
│
├── 1. Pre-Lazy Phase
│   ├── Set global state: vim.g.mapleader, base46 cache directory
│   ├── Prepend Mason bin directory to vim.env.PATH
│   ├── require("config.options")   -- Baseline Vim options, tabstops, providers
│   ├── require("config.autocmds")  -- NvFilePost, Treesitter start, UI triggers
│   └── require("config.filetypes") -- Custom filetype associations
│
├── 2. Lazy.nvim Bootstrap & Setup
│   └── require("lazy").setup({ { import = "plugins" } }, require("config.lazy"))
│       -- Recursively imports pure LazySpec definitions from lua/plugins/
│
└── 3. Post-Lazy Phase
    ├── require("cmds").setup()     -- Declarative user commands (ai, python, system, treesitter)
    ├── require("config.theme")     -- Load Base46 compiled highlights caches
    ├── require("utils.shell")      -- Configure default shell environments
    ├── require("utils.hl")         -- Apply extra highlight groups
    └── require("config.keymaps")   -- User-facing keybindings
```

### Directory Layout

```text
.
├── init.lua                     # 3-phase bootstrap and startup orchestrator
├── lua/
│   ├── chadrc.lua               # Nv UI and base46 theme overrides
│   ├── config/                  # Core settings and domain configurations
│   │   ├── options.lua          # Baseline editor options and Mason PATH prepend
│   │   ├── keymaps.lua          # General keybindings
│   │   ├── autocmds.lua         # Autocommands (deferred FilePost, Treesitter, etc.)
│   │   ├── filetypes.lua        # Filetype definitions
│   │   ├── lazy.lua             # lazy.nvim configuration
│   │   ├── theme.lua            # Base46 cache loader
│   │   ├── tools.lua            # Canonical tool registry (LSP, DAP, format, lint, parsers)
│   │   ├── packages.lua         # Derived Mason packages and Treesitter lists
│   │   ├── lsp/                 # LSP server configs, handlers, schemas, and keymaps
│   │   ├── dap/                 # DAP adapters and language debug configurations
│   │   ├── formatter/           # Conform.nvim formatter defaults and runtime wrapper
│   │   └── linter/              # nvim-lint linter defaults and runtime wrapper
│   ├── plugins/                 # Pure lazy.nvim plugin specs (LazySpec[])
│   │   ├── lsp.lua              # Mason & nvim-lspconfig specifications
│   │   ├── dap.lua              # nvim-dap & dap-ui specifications
│   │   ├── completion.lua       # blink.cmp & LuaSnip
│   │   ├── editor.lua           # Treesitter, comments, mini.icons, etc.
│   │   ├── navigation.lua       # nvim-tree, harpoon, snacks
│   │   ├── ui/                  # Statusline, tabufline, noice, trouble, which-key
│   │   └── ...                  # Other feature-specific plugin specs
│   ├── tool/                    # Tool Manager UI, state persistence, and Mason bridge
│   ├── ai/                      # AI completion endpoints, health checks, and statusline
│   ├── cmds/                    # User commands (ai, python, system, treesitter)
│   └── utils/                   # Shared utility helpers (fs, os, str, table, term, etc.)
├── luasnippets/                 # Custom LuaSnip snippet collections
└── scripts/tests/minimal.vim    # Test runner bootstrap
```

---

## Getting Started

### Prerequisites

- **Neovim 0.10+**
- **Git**
- **C Compiler** (`gcc` or `clang`) for building Treesitter parsers
- Language runtimes for stacks in use (.NET SDK, Python, Node.js, Go)
- *(Optional)* **Ollama** running locally or accessible over network for AI code completion

For development and test validation, install `make`, `stylua`, `luacheck`, and `tree-sitter-cli` (0.26.1+).

### Installation

Clone OrbitVim into your Neovim configuration directory:

```bash
git clone https://github.com/Orbit-Lua/orbitvim.git ~/.config/nvim
```

Launch Neovim:

```bash
nvim
```

On first launch, `lazy.nvim` bootstraps automatically and installs all declared plugins.

To install all configured Treesitter parsers:

```vim
:TSInstallAll
```

---

## Usage & Workflows

### Tool Manager

Open the interactive Tool Manager to manage installed tools, parsers, and priorities:

```vim
:ToolManager
```
*(Shortcut: `<leader>us`)*

| Key | Action |
| --- | --- |
| `1` - `6` | Jump directly to category (LSP, DAP, Formatter, Linter, Parser, Package) |
| `<Tab>` / `<S-Tab>` | Cycle next / previous category |
| `<Space>` | Toggle enable / disable for the selected tool |
| `i` | Install missing Mason package or Treesitter parser |
| `[` / `]` | Reorder formatter or linter runtime priority |
| `K` | View detailed tool tooltip (mason package, filetypes, documentation) |
| `o` / `<CR>` / `za` | Expand / collapse grouped entries |
| `g?` | Toggle help overlay |
| `q` / `<Esc>` | Exit Tool Manager |

### Common Editor Shortcuts

| Mapping | Action |
| --- | --- |
| `<leader>us` | Open Tool Manager |
| `<leader>ut` | Open Base46 theme picker |
| `<leader>fm` | Format active buffer via Conform |
| `<leader>tf` | Show floating diagnostics for current line |
| `<C-n>` | Toggle file explorer tree |
| `<leader>e` | Focus file explorer tree |
| `<C-e>` | Toggle Harpoon quick menu |
| `<leader>dt` | Toggle DAP breakpoint |
| `<leader>du` | Toggle DAP UI layout |
| `<M-i>` | Toggle floating terminal |
| `<M-h>` | Toggle horizontal terminal |
| `<M-v>` | Toggle vertical terminal |

### AI Completion (Minuet & Ollama)

OrbitVim integrates with Ollama for local LLM completion via Minuet. It defaults to `http://127.0.0.1:11434`.

Switch or add endpoints interactively:

```vim
:MinuetEndpoint
:MinuetEndpoint 100.64.0.8
:MinuetEndpoint https://workstation.example.ts.net
```

- OrbitVim validates endpoint health before persisting to prevent editor hangs or error popups.
- Remove remote endpoints with `:MinuetEndpoint!`.

### Database & SQL Development

- **SQLFluff Integration**: Pre-configured with a DataGrip-compatible profile, supporting file-level dialect directives (e.g. `-- sqlfluff:dialect:postgres`).
- **T-SQL Syntax & Treesitter**: Corrects T-SQL dialect quirks in both `.sql` files and Markdown code blocks.
- **Convention-based Snippets**: Specialized T-SQL snippets (`ctable`, `cview`, `sel`, `ins`, `trycatch`, etc.) enforcing strict schema naming and transaction safety.

---

## Development & Testing

OrbitVim includes a comprehensive automated test suite powered by Plenary Busted.

| Command | Description |
| --- | --- |
| `make fmt` | Format Lua code using StyLua |
| `make fmt-check` | Check code formatting without modifying files |
| `make lint` | Run Luacheck static analysis |
| `make test` | Run hermetic unit tests in `lua/test/spec/` |
| `make test-integration` | Run integration tests (Treesitter queries, SQLFluff, snippets) |
| `make all` | Run full validation: format check, lint, and core test specs |
| `nvim --headless "+qall"` | Smoke test the complete startup path |

Run an individual test spec:

```bash
nvim --headless --noplugin -u scripts/tests/minimal.vim \
  -c "PlenaryBustedFile lua/test/spec/tool_state_spec.lua {minimal_init = 'scripts/tests/minimal.vim'}"
```
