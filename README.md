# OrbitVim

[![Check](https://img.shields.io/github/actions/workflow/status/Orbit-Lua/orbitvim/validate.yml?branch=main&label=check&logo=githubactions&logoColor=white)](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml)
[![Neovim 0.12+](https://img.shields.io/badge/Neovim-0.12%2B-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io/)

A Lua Neovim configuration for C#, Python, JavaScript, TypeScript, Go, SQL and Markdown, with a Tool Manager that installs, enables and orders language tools from one view.

## Install

Requirements:

- Neovim 0.12 or newer, Git, and network access for the first start.
- A C compiler and Tree-sitter CLI 0.26.1 or newer to build parsers; GNU Make and Bash for native plugin builds.
- The runtimes and package managers of your languages; `:checkhealth mason` lists the installers Mason can use.

Move any existing configuration aside, then clone into the directory printed by `:echo stdpath('config')` (`~/.config/nvim` on Linux, `%LOCALAPPDATA%\nvim` on Windows):

```sh
git clone https://github.com/Orbit-Lua/orbitvim.git ~/.config/nvim
nvim
```

Lazy installs the locked plugin versions on first start. Language tools are installed separately: press `i` on a tool in Tool Manager, or run `:TSInstallAll` to build every configured parser.

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

Parsers and dependency packages can only be installed. Enablement and priority persist in `tools.json` in Neovim's data directory. The [Tool Manager guide](doc/tool-manager.md) explains each status and the install policy.

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

Terminal image previews are off; press `s` on an image in nvim-tree to open it in the system viewer.

### .NET

Roslyn starts for C# files when `dotnet` and `roslyn-language-server` are on PATH; install the server from Tool Manager and restart Neovim. When several solutions are found above the file, OrbitVim prefers the single `.sln` at the Git root that contains the current project; `:Roslyn target` picks one manually.

`:DotnetManager` (`<leader>ud`) runs build, test, package, EF Core and publish actions for SDK-style projects. `:DotnetDebug` builds and launches the startup project and `:DotnetAttach` attaches to a process; both need `netcoredbg` installed and `coreclr` enabled in Tool Manager.

### SQL

T-SQL uses Tree-sitter highlighting, SQLFluff formatting and linting, and LuaSnip templates. SQLFluff lints when a file is read or saved and when you leave Insert mode, not after each edit. See the [highlighting guide](doc/tsql-highlighting.md), [snippet catalog](doc/tsql-snippets.md) and [SQL conventions](doc/tsql-conventions.md).

### Python

`:PyrightReCreateStub` regenerates a selected package in the current project's `typings` directory. The previous stub is kept until generation succeeds and restored after a failure; recovery errors name the backup's location.

## Configuration

Press `<leader>uc` or run `:OrbitSettings` to open `settings.json`. The command creates a minimal file linked to the bundled JSON Schema; enable `jsonls` in Tool Manager for completion and validation. Git ignores this file.

```json
{
  "$schema": "./settings.schema.json",
  "editor": { "relativenumber": false, "shiftwidth": 4 },
  "tool_manager": { "width": 100, "missing_package_policy": "manual" }
}
```

Set `notes.vault` to an Obsidian vault directory to load obsidian.nvim for Markdown files.

Saving applies editor options, Tool Manager options and inlay hints immediately. Server settings, code lenses and initial tool priorities take effect after a restart. Invalid settings keep the last valid values. `:OrbitSettings reload` rereads the file; `:OrbitSettings info` shows effective values, their sources and pending restart changes. Omitted settings use the schema defaults. Saved order in `tools.json` takes precedence over initial priorities in settings. The [settings guide](doc/settings.md) covers merge rules and scope.

## Supported platforms

Linux and Windows run the same test suites, native build checks and startup check in CI.

On Windows:

- Shell setup keeps an explicitly configured `shell` and `CC`; otherwise it selects an available PowerShell and C compiler.
- Use native Windows Git. MSYS2's UCRT64 `bin` and `usr/bin` directories provide GCC, Make and Bash; add them to PATH without replacing Git.
- nvim-tree's filesystem watchers are off; the tree refreshes on save or when entered, and `R` refreshes it in place.
- `:ClearShada` deletes leftover temporary ShaDa files and keeps `main.shada`.

## License

No license has been published; all rights are reserved by the authors.
