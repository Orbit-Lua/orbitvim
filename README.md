<!-- markdownlint-disable MD013 -->

# OrbitVim

[![Validate on main](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml/badge.svg?branch=main)](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml?query=branch%3Amain)
[![Neovim 0.12 or newer](https://img.shields.io/badge/Neovim-0.12%2B-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io/)
[![Managed with lazy.nvim](https://img.shields.io/badge/plugins-lazy.nvim-blue?style=flat-square)](https://github.com/folke/lazy.nvim)

OrbitVim is a Neovim configuration for development in C#, Python, JavaScript, TypeScript, Go, SQL, Markdown, and related files. It combines lazy-loaded plugins, Nv UI/base46, language tooling, and an interactive Tool Manager. The layout is intended to make both everyday use and customization easy to navigate.

## Quick start

You need Neovim **0.12 or newer** and Git. A C compiler and Tree-sitter CLI **0.26.1 or newer** are needed when building configured parsers. Language tools may need their own runtimes, such as .NET, Python, Node.js, or Go.

On Linux or macOS, clone into Neovim's configuration directory. If you already have a configuration at `~/.config/nvim`, move it aside first.

```sh
git clone https://github.com/Orbit-Lua/orbitvim.git ~/.config/nvim
nvim
```

The first launch downloads `lazy.nvim` and the declared plugins, so it needs network access. After plugin installation, run `:ToolManager`. A window with LSP, DAP, formatter, linter, parser, and package tabs confirms that the configuration loaded. `<leader>us` opens the same window; the leader key is Space.

To install every configured Tree-sitter parser, run `:TSInstallAll`. This downloads and builds parsers. You can also install individual missing tools from Tool Manager.

On Windows, place the checkout at the path returned by `:echo stdpath('config')`, then start Neovim in the usual way.

## What is included

- **Tool Manager:** inspect available language tools, enable or disable them, install missing Mason packages and parsers, and change formatter or linter order.
- **Language features:** LSP, debugging for Python and .NET, formatting, linting, completion, and snippets.
- **Editing and UI:** Nv UI/base46 themes, file navigation, diagnostics, terminals, Git signs, and context menus.
- **SQL support:** T-SQL highlighting, SQLFluff integration, and project-local LuaSnip templates. See [highlighting](doc/tsql-highlighting.md), [snippets](doc/tsql-snippets.md), and [conventions](doc/tsql-conventions.md).

Minuet/Ollama completion code is included but its plugin is **disabled by default**. The `:MinuetEndpoint` command manages endpoint settings; it does not enable the disabled plugin.

### .NET development

Open `:DotnetManager` in an SDK-style C# workspace to choose a startup project and run build, test, package, EF Core, diagnostics, and publish actions. `:DotnetDebug` builds and launches the selected project; `:DotnetAttach` attaches to a local process. Install `netcoredbg` and enable `coreclr` in Tool Manager's DAP tab. `dotnet-cli.nvim` supplies the .NET launch and attach configurations while OrbitVim keeps the generic DAP keys and UI. See the [dotnet-cli.nvim guide](https://github.com/Orbit-Lua/dotnet-cli.nvim) for optional tools and profiles.

## Tool Manager

Run `:ToolManager` or press `<leader>us`.

| Key | Action |
| --- | --- |
| `1`–`6` | Select LSP, DAP, formatter, linter, parser, or package |
| `<Tab>` / `<S-Tab>` | Move between categories |
| `<Space>` | Enable or disable a tool |
| `i` | Install a missing package or parser |
| `[` / `]` | Change formatter or linter priority |
| `o` / `<CR>` / `za` | Expand or collapse an entry |
| `K` | Show details for the selected tool |
| `s` | Switch between current-buffer and all-state views |
| `?` / `g?` | Show help |
| `q` / `<Esc>` | Close |

Tool definitions and default ordering come from `lua/config/tools.lua`. Tool Manager saves enabled state and ordering in Neovim's data directory as `tools.json`; it can read an older `service.json` state file.

## Common shortcuts

| Mapping | Action |
| --- | --- |
| `<leader>us` | Open Tool Manager |
| `<leader>ut` | Open the theme picker |
| `<leader>fm` | Format the current buffer |
| `<leader>tf` | Show diagnostics for the current line |
| `<C-n>` | Toggle the file tree |
| `<leader>fe` | Focus the file tree |
| `<C-e>` | Open Harpoon's quick menu |
| `<leader>dt` | Toggle a breakpoint |
| `<leader>du` | Toggle the debug UI |
| `<M-i>` / `<M-h>` / `<M-v>` | Toggle floating, horizontal, or vertical terminal |

## Where to customize

`init.lua` shows the startup sequence: editor setup, Lazy plugin import, then post-Lazy commands and theme setup. Each directory has one main role:

| Change | Location |
| --- | --- |
| Editor options, filetypes, events, general keys, theme activation | `lua/core/` |
| Plugin identity, dependencies, lazy triggers, plugin keys | `lua/plugins/` |
| Plugin options, tool registry, language and UI settings | `lua/config/` |
| LSP, DAP, completion, formatter, linter, and snippet activation | `lua/runtime/` |
| User command registration | `lua/commands/` |
| Tool Manager state, actions, adapters, and UI | `lua/tool/` |
| AI endpoint state and statusline integration | `lua/ai/` |
| Reusable helpers | `lua/utils/` |

To change a tool or its filetypes, start in `lua/config/tools.lua`. To change a plugin's loading condition, find its spec in `lua/plugins/`. For plugin behavior, follow its runtime module. `lua/chadrc.lua` remains the Nv UI/base46 entry point.

## Development

Work from the repository root. Install Neovim, `make`, StyLua, Luacheck, and Tree-sitter CLI 0.26.1 or newer. Open Neovim once so `lazy.nvim` and `plenary.nvim` are available. Integration tests also need the configured parsers and external tools, including SQLFluff.

| Command | Checks or changes |
| --- | --- |
| `make all` | Check formatting, lint, and run hermetic core specs |
| `make test-integration` | Run parser, snippet, and executable integration specs |
| `make test-all` | Run both test suites |
| `make fmt` | Rewrite Lua formatting |
| `nvim --headless "+qall"` | Smoke-test startup |

`make all` checks the local source tree; the badge above reports the repository's main-branch workflow. For a single core spec:

```sh
nvim --headless --noplugin -u scripts/tests/minimal.vim \
  -c "lua require('plenary.busted').run('lua/test/spec/tool_state_spec.lua')" \
  -c 'qall'
```

Repository editing and test isolation rules are in [AGENTS.md](AGENTS.md).
