<!-- markdownlint-disable MD013 -->

# OrbitVim

[![Validate on main](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml/badge.svg?branch=main)](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml?query=branch%3Amain)
[![Neovim 0.12+](https://img.shields.io/badge/Neovim-0.12%2B-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io/)
[![lazy.nvim](https://img.shields.io/badge/plugins-lazy.nvim-blue?style=flat-square)](https://github.com/folke/lazy.nvim)
[![Nui UI](https://img.shields.io/badge/Tool_Manager-nui.nvim-blue?style=flat-square)](https://github.com/MunifTanjim/nui.nvim)

A Lua Neovim configuration with language tooling, debugging, completion, Nv UI/base46 themes, and a Nui-based Tool Manager. It supports C#, Python, JavaScript, TypeScript, Go, SQL, Markdown, and related files. Tool Manager brings tool availability, runtime health, installation, and formatter/linter priority into one view.

[Getting started](#getting-started) · [Tool Manager](#tool-manager) · [Customization](#customization) · [Development](#development)

## Getting started

You need **Neovim 0.12 or newer**, Git, and network access for the first plugin installation. Building Tree-sitter parsers also requires a C compiler and **Tree-sitter CLI 0.26.1 or newer**. Install the runtimes and package managers required by the languages you use; `:checkhealth mason` reports the available installation tools.

On Linux or macOS, clone into Neovim's configuration directory. Move any existing configuration aside before using this destination:

```sh
git clone https://github.com/Orbit-Lua/orbitvim.git ~/.config/nvim
nvim
```

On Windows, use the configuration path returned by `:echo stdpath('config')`.

Let Lazy finish installing plugins, then run `:ToolManager` or press `<leader>us` (Space, `u`, `s`). The category navigation and tools for your source buffer confirm that the configuration loaded. Press `s` to see all registered tool states.

Missing language tools are installed separately from plugins. Select a tool and press `i`, or enable a missing Mason-backed tool with Space: the default policy installs it before enabling it. To download and build every configured parser, run `:TSInstallAll`.

## Tool Manager

The six categories are **LSP, DAP, Linter, Formatter, Parser, Package**. The view opens in the current buffer's scope; switching to all states lets you inspect tools for other filetypes. Formatter and linter entries are grouped by filetype, with their priority visible in the expanded group.

| Key | Action |
| --- | --- |
| `1`–`6` | Select a category |
| `<Tab>` / `<S-Tab>` | Next / previous category |
| `s` | Current buffer / all tool states |
| `<Space>` | Enable or disable a tool |
| `i` | Install its package or parser |
| `[` / `]` | Move a formatter or linter earlier / later |
| `o` / `<CR>` / `za` | Expand or collapse an entry |
| `K` | Open details, including linter errors and diagnostics |
| `?` / `g?` | Toggle help |
| `q` / `<Esc>` | Close the view |

Parsers and dependency packages can be installed but cannot be toggled or reordered. Enabling a tool and installing its package are separate operations: `i` alone does not change enablement. A failed automatic installation leaves the tool disabled.

Enablement and priority are saved as `tools.json` in Neovim's data directory. An older `service.json` is read when `tools.json` is absent. Tool support and initial runtime activation are distinct: a registered tool can support your filetype while its status reports that it is not configured.

See the [Tool Manager guide](doc/tool-manager.md) for status interpretation, install policy, and persistence behavior.

## Everyday workflows

| Mapping | Action |
| --- | --- |
| `<leader>fm` | Format the current buffer |
| `<leader>tf` | Show diagnostics for the current line |
| `<C-n>` | Toggle the file tree |
| `<leader>fe` | Focus the file tree |
| `<C-e>` | Open Harpoon's quick menu |
| `<leader>dt` | Toggle a breakpoint |
| `<leader>du` | Toggle the debug UI |
| `<M-i>` / `<M-h>` / `<M-v>` | Floating / horizontal / vertical terminal |
| `<leader>ut` | Choose a theme |

### .NET

In an SDK-style C# workspace, `:DotnetManager` provides startup-project selection, build, test, package, EF Core, diagnostics, and publish actions. `:DotnetDebug` builds and launches the selected project; `:DotnetAttach` attaches to a local process. Install `netcoredbg` and enable `coreclr` in Tool Manager. [dotnet-cli.nvim](https://github.com/Orbit-Lua/dotnet-cli.nvim) owns the launch/attach configurations; OrbitVim supplies generic DAP mappings and UI.

### SQL

T-SQL support combines Tree-sitter highlighting, focused syntax fallbacks, SQLFluff formatting/linting adapters, and LuaSnip templates. Read the [highlighting guide](doc/tsql-highlighting.md), [snippet catalog](doc/tsql-snippets.md), and [SQL conventions](doc/tsql-conventions.md).

### AI completion

Minuet/Ollama completion is included but disabled by default. `:MinuetEndpoint` manages endpoint settings; it does not enable the plugin. Its plugin specification is in [lua/plugins/ai.lua](lua/plugins/ai.lua).

## Customization

| Responsibility | Owner |
| --- | --- |
| Editor options, events, filetypes, keys, theme activation | `lua/core/` |
| Plugin identities, dependencies, lazy triggers, plugin keys | `lua/plugins/` |
| Editable plugin and language settings | `lua/config/` |
| Canonical tools, filetypes, installer packages, default priority | `lua/config/tools.lua` |
| Tool Manager dimensions, categories, mappings, install policy | `lua/config/tool_manager.lua` |
| LSP, DAP, completion, formatting, linting, snippets, Tree-sitter activation | `lua/runtime/` |
| User command registration | `lua/commands/` |
| Tool operations, persistence, category adapters | `lua/tool/` |
| Nui view sessions, rendering, details | `lua/tool/ui/` |
| AI endpoint persistence and statusline | `lua/ai/` |
| Shared helpers | `lua/utils/` |

`lua/chadrc.lua` is the Nv UI/base46 entry point. `init.lua` preserves three startup phases: editor setup, Lazy bootstrap/import, then commands and final UI setup. See [architecture](doc/architecture.md) for the module boundaries.

## Development

Install Neovim, `make`, StyLua, and Luacheck. Open Neovim once to bootstrap the locked plugins, including Plenary and Nui. Integration tests additionally require the configured parsers, LuaSnip, and SQLFluff; use `:TSInstallAll` to prepare parsers.

Run commands from the repository root:

| Command | Effect |
| --- | --- |
| `make all` | Check formatting, lint, and run hermetic core specs |
| `make test-integration` | Run parser, snippet, and executable integration specs |
| `make test-all` | Run both suites |
| `make fmt` | Rewrite Lua formatting |
| `nvim --headless "+qall"` | Smoke-test startup with installed plugins |

For one core spec:

```sh
nvim --headless --noplugin -u scripts/tests/minimal.vim \
  -c "lua require('plenary.busted').run('tests/core/tool_state_spec.lua')" \
  -c 'qall'
```

Core tests use isolated files and mocked installation/runtime seams; they do not install tools or update plugins. UI contract specs exercise the installed Nui library. Integration suites fail when a required dependency is missing.

[AGENTS.md](AGENTS.md) defines editing and test admission rules. Tests protect behavior, safety, persistence, ordering, or external seams; moving a file or adding a constant does not require another test.
