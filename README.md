# OrbitVim

Lua configuration for Neovim with language tooling for C#, Python, JavaScript, TypeScript, Go, SQL and Markdown.

[![check](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml/badge.svg?branch=main)](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml)
[![Neovim](https://img.shields.io/badge/Neovim-0.12%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)

## Install

Use Neovim 0.12+, Git and network access. Parser and native plugin builds need a C compiler, Tree-sitter CLI 0.26.1+, GNU Make and Bash. Language servers can also need the runtime or package manager of their language. `:checkhealth mason` reports the available installers.

Move the existing configuration aside. Clone into `stdpath('config')`: `~/.config/nvim` on Linux or `%LOCALAPPDATA%\nvim` on Windows.

```sh
git clone https://github.com/Orbit-Lua/orbitvim.git ~/.config/nvim
nvim
```

Lazy installs the locked plugins on first start. Install language tools through Tool Manager. Install parsers with `:TSInstallAll`.

## Usage

To manage tools for the current buffer, run `:ToolManager` or press `<leader>us` (Space, `u`, `s`).

| Key | Action |
| --- | --- |
| `1`–`6`, Tab / Shift-Tab | Select LSP, DAP, Linter, Formatter, Parser or Package |
| `s` | Switch between buffer scope and all tools |
| Space | Install a missing Mason package, then toggle the runtime tool |
| `i` | Install without changing enablement |
| `[` / `]` | Reorder a formatter or linter for a filetype |
| `o`, Enter, `za` | Expand or collapse a filetype group |
| `K` | Focus details |
| `?`, `g?` | Toggle help |
| `q`, Escape | Close |

Parsers and dependency packages support installation only. Enablement and order persist in `tools.json` in the data directory. See [Tool Manager](doc/tool-manager.md).

| Key | Action |
| --- | --- |
| `<leader>fm` | Format the buffer |
| `<leader>tf` | Show current-line diagnostics |
| `<C-n>` / `<leader>fe` | Toggle / focus the file tree |
| `<C-e>` | Open Harpoon |
| `<leader>dt` / `<leader>du` | Toggle breakpoint / debug UI |
| `<M-i>` / `<M-h>` / `<M-v>` | Open floating / horizontal / vertical terminal |
| `<leader>ut` | Choose a theme |

Press `s` on an image in nvim-tree to open the system viewer. Terminal image previews are disabled.

### Language workflows

- **C#:**
  1. Put `dotnet` and `roslyn-language-server` on PATH.
  2. Install the server through Tool Manager.
  3. Restart Neovim.

  Roslyn prefers a single solution at the Git root that contains the current project. To select one manually, use `:Roslyn target`. `:DotnetManager` (`<leader>ud`) gives build, test, package, EF Core and publish actions. `:DotnetDebug` and `:DotnetAttach` need `netcoredbg` and enabled `coreclr` tools.
- **SQL:** SQLFluff formats and lints T-SQL. Linting runs on read, on save and when you exit Insert mode. Tree-sitter and a bounded syntax fallback give [highlighting](doc/tsql-highlighting.md). [LuaSnip templates](doc/tsql-snippets.md) follow the [SQL conventions](doc/tsql-conventions.md).
- **Python:** `:PyrightReCreateStub` regenerates a package stub under the project's `typings` directory. It keeps the old stub until the new one succeeds. A failed recovery reports the backup path.

## Configuration

`:OrbitSettings` or `<leader>uc` opens `settings.json`, which Git ignores. It creates the file only when it is missing. Enable `jsonls` for schema completion and validation.

```json
{
  "$schema": "./settings.schema.json",
  "editor": { "relativenumber": false, "shiftwidth": 4 },
  "tool_manager": { "width": 100, "missing_package_policy": "manual" }
}
```

A save applies editor options, Tool Manager options and inlay hints. Server configuration, code lenses, initial tool priorities and notes settings need a restart. Invalid input keeps the accepted values. `:OrbitSettings reload` reads the file again. `:OrbitSettings info` shows active values, sources and pending changes. See [settings](doc/settings.md) for merge and rollback rules.

Set `notes.vault` to an Obsidian vault path to enable obsidian.nvim for Markdown.

## Supported platforms

Linux and Windows run the same core, integration, native build and startup checks in CI. On Windows, keep native Git. Add MSYS2 UCRT64 GCC, Make and Bash to PATH, but not the MSYS Git. OrbitVim keeps explicit `shell` and `CC` choices. Otherwise it selects available defaults. nvim-tree has no filesystem watchers. It refreshes on save, on entry and with `R`. `:ClearShada` removes temporary ShaDa files and keeps `main.shada`.
