# OrbitVim

Lua configuration for Neovim with language tooling for C#, Python, JavaScript, TypeScript, Go, SQL and Markdown.

[![check](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml/badge.svg?branch=main)](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml)
[![Neovim](https://img.shields.io/badge/Neovim-0.12%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)

## Install

Use Neovim 0.12+, Git and network access. Parser and native plugin builds need a C compiler, Tree-sitter CLI 0.26.1+, GNU Make and Bash. Language servers may also need their language's runtime or package manager; `:checkhealth mason` reports available installers.

Move existing configuration aside. Clone into `stdpath('config')`: `~/.config/nvim` on Linux or `%LOCALAPPDATA%\nvim` on Windows.

```sh
git clone https://github.com/Orbit-Lua/orbitvim.git ~/.config/nvim
nvim
```

Lazy installs locked plugins on first start. Install language tools through Tool Manager and parsers with `:TSInstallAll`.

## Usage

Run `:ToolManager` or press `<leader>us` (Space, `u`, `s`) to manage tools for the current buffer.

| Key | Action |
| --- | --- |
| `1`–`6`, Tab / Shift-Tab | Select LSP, DAP, Linter, Formatter, Parser or Package |
| `s` | Switch between buffer scope and all tools |
| Space | Toggle a runtime tool; install its missing Mason package first |
| `i` | Install without changing enablement |
| `[` / `]` | Reorder a formatter or linter for a filetype |
| `o`, Enter, `za` | Expand or collapse a filetype group |
| `K` | Focus details |
| `?`, `g?` | Toggle help |
| `q`, Escape | Close |

Parsers and dependency packages support installation only. Enablement and ordering persist in the data directory's `tools.json`; see [Tool Manager](doc/tool-manager.md).

| Key | Action |
| --- | --- |
| `<leader>fm` | Format the buffer |
| `<leader>tf` | Show current-line diagnostics |
| `<C-n>` / `<leader>fe` | Toggle / focus the file tree |
| `<C-e>` | Open Harpoon |
| `<leader>dt` / `<leader>du` | Toggle breakpoint / debug UI |
| `<M-i>` / `<M-h>` / `<M-v>` | Open floating / horizontal / vertical terminal |
| `<leader>ut` | Choose a theme |

Press `s` on an image in nvim-tree to open the system viewer; terminal image previews are disabled.

### Language workflows

- **C#:** put `dotnet` and `roslyn-language-server` on PATH; install the server through Tool Manager and restart. Roslyn prefers a single Git-root solution containing the current project; use `:Roslyn target` to choose manually. `:DotnetManager` (`<leader>ud`) provides build, test, package, EF Core and publish actions. `:DotnetDebug` and `:DotnetAttach` need `netcoredbg` and enabled `coreclr` tooling.
- **SQL:** SQLFluff provides T-SQL formatting and linting; linting runs on read, save and Insert-mode exit. Tree-sitter and a bounded syntax fallback provide [highlighting](doc/tsql-highlighting.md); [LuaSnip templates](doc/tsql-snippets.md) follow the [SQL conventions](doc/tsql-conventions.md).
- **Python:** `:PyrightReCreateStub` regenerates a package under the project's `typings` directory, preserving the old stub until success. Recovery failures report the backup path.

## Configuration

`:OrbitSettings` or `<leader>uc` opens the ignored `settings.json`, creating it only when missing. Enable `jsonls` for schema completion and validation.

```json
{
  "$schema": "./settings.schema.json",
  "editor": { "relativenumber": false, "shiftwidth": 4 },
  "tool_manager": { "width": 100, "missing_package_policy": "manual" }
}
```

Saving applies editor options, Tool Manager options and inlay hints. Server configuration, code lenses, initial tool priorities and notes settings require a restart. Invalid input keeps accepted values. `:OrbitSettings reload` rereads the file; `:OrbitSettings info` shows active values, sources and pending changes. See [settings](doc/settings.md) for merge and rollback rules.

Set `notes.vault` to an Obsidian vault path to enable obsidian.nvim for Markdown.

## Supported platforms

Linux and Windows run the same core, integration, native build and startup checks in CI. On Windows, keep native Git and expose MSYS2 UCRT64 GCC, Make and Bash without replacing Git. Explicit `shell` and `CC` choices are preserved; otherwise OrbitVim selects available defaults. nvim-tree refreshes on save or entry and with `R`, with filesystem watchers disabled. `:ClearShada` removes temporary ShaDa files while preserving `main.shada`.
