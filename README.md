# OrbitVim

[![Validate](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml/badge.svg?branch=main)](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml?query=branch%3Amain)
[![Neovim 0.12+](https://img.shields.io/badge/Neovim-0.12%2B-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io/)

A Lua Neovim configuration for C#, Python, JavaScript, TypeScript, Go, SQL and Markdown, with LSP, debugging, completion, Nv UI/base46 themes, and a Tool Manager that installs, enables and orders language tools from one view.

## Install

Requirements:

- Neovim 0.12 or newer, Git, and network access for the first plugin installation.
- A C compiler and Tree-sitter CLI 0.26.1 or newer to build parsers, plus GNU Make and Bash for native plugin builds.
- The runtimes and package managers for your languages; `:checkhealth mason` lists the installers it can use.

Clone into Neovim's configuration directory, after moving any existing configuration aside:

```sh
git clone https://github.com/Orbit-Lua/orbitvim.git ~/.config/nvim
nvim
```

Linux and Windows are validated in CI with the same full test suites and native build checks. On Windows, clone into the path printed by `:echo stdpath('config')`.

Lazy installs the locked plugin versions on first start. Language tools are installed separately: open Tool Manager and press `i` on a tool, or run `:TSInstallAll` to build every configured parser.

## Usage

Run `:ToolManager` or press `<leader>us` (Space, `u`, `s`). The view opens on the tools for the current buffer's filetype.

| Key | Action |
| --- | --- |
| `1`–`6`, `<Tab>` / `<S-Tab>` | Switch category: LSP, DAP, Linter, Formatter, Parser, Package |
| `s` | Toggle between current-buffer and all tool states |
| `<Space>` | Enable or disable a tool; a missing Mason package is installed first |
| `i` | Install the package or parser without changing enablement |
| `[` / `]` | Move a formatter or linter earlier or later for the filetype |
| `o` / `<CR>` / `za` | Expand or collapse a filetype group |
| `K` | Focus the scrollable details pane |
| `?` / `g?` | Toggle help |
| `q` / `<Esc>` | Close |

Parsers and dependency packages can only be installed, not toggled or reordered. Enablement and priority persist in `tools.json` in Neovim's data directory. The [Tool Manager guide](doc/tool-manager.md) explains each status and the install policy.

Other mappings:

| Key | Action |
| --- | --- |
| `<leader>fm` | Format the buffer |
| `<leader>tf` | Show diagnostics for the current line |
| `<C-n>` / `<leader>fe` | Toggle / focus the file tree |
| `<C-e>` | Harpoon quick menu |
| `<leader>dt` / `<leader>du` | Toggle breakpoint / debug UI |
| `<M-i>` / `<M-h>` / `<M-v>` | Floating / horizontal / vertical terminal |
| `<leader>ut` | Choose a theme |

### .NET

Roslyn starts for C# files when `dotnet` and `roslyn-language-server` are on PATH; install the server from Tool Manager and restart Neovim. When several solutions are found above the file, OrbitVim prefers the single `.sln` at the Git root if it contains the current project; `:Roslyn target` picks one manually.

`:DotnetManager` (`<leader>ud`) runs build, test, package, EF Core and publish actions for SDK-style projects. `:DotnetDebug` builds and launches the startup project and `:DotnetAttach` attaches to a process; both need `netcoredbg` installed and `coreclr` enabled in Tool Manager.

### SQL

T-SQL uses Tree-sitter highlighting, SQLFluff formatting and linting, and LuaSnip templates. See the [highlighting guide](doc/tsql-highlighting.md), [snippet catalog](doc/tsql-snippets.md) and [SQL conventions](doc/tsql-conventions.md).

### Python

`:PyrightReCreateStub` regenerates a selected package in the current project's `typings` directory. It retains the previous stub until generation succeeds and restores it after a failed process. Recovery errors include the retained backup's location.

### Windows notes

nvim-tree's filesystem watchers are off on Windows to avoid event storms: the tree refreshes on save or when entered, and `R` refreshes it in place. Terminal image previews are off on every platform; press `s` on an image in nvim-tree to open the system viewer.

Shell setup preserves an explicitly configured shell and `CC`. Otherwise it selects an available PowerShell and C compiler. Use native Windows Git. MSYS2's UCRT64 compiler and `usr/bin` provide GCC, Make and Bash; put these directories on PATH without replacing Git with its MSYS build.

## Configuration

Press `<leader>uc` or run `:OrbitSettings` to open `settings.json`. The command creates a minimal file linked to the bundled JSON Schema. Install `json-lsp` and enable `jsonls` in Tool Manager for completion, hover descriptions and validation. The personal settings file is ignored by Git.

```json
{
  "$schema": "./settings.schema.json",
  "editor": { "relativenumber": false, "shiftwidth": 4 },
  "tool_manager": { "width": 100, "missing_package_policy": "manual" }
}
```

Saving applies supported settings automatically. `:OrbitSettings reload` reloads from disk; `:OrbitSettings info` shows effective values, their sources and changes requiring a restart. Editor options, Tool Manager options and inlay hints update live. Server settings, code lenses and initial tool priorities take effect after restarting. Invalid settings preserve the last valid values.

Omitted settings use the defaults in `settings.schema.json`; `{}` uses all defaults. Tool Manager continues saving enablement and priority in the data directory's `tools.json`, which takes precedence over initial priorities in settings. See the [settings guide](doc/settings.md) for merge rules and scope.

Plugin choices and loading rules remain in `lua/plugins/`; Lua callbacks and language-specific options remain with their owners in `lua/config/` and `lua/runtime/`. [Architecture](doc/architecture.md) describes the module responsibilities.

## License

No license has been published; all rights are reserved by the authors.
