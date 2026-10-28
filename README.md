# OrbitVim

Neovim configuration for programming, SQL and Markdown, with persistent language tooling on Linux and Windows.

[![Validate OrbitVim](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml/badge.svg?branch=main)](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml) [![Neovim](https://img.shields.io/badge/Neovim-0.12%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)

## Install

Use Neovim 0.12+, Git and network access. Parser and native plugin builds need a C compiler, Tree-sitter CLI 0.26.1+, GNU Make and Bash. Language servers can also need their language runtime or package manager. `:checkhealth mason` reports available installers.

Move any existing configuration aside before cloning.

Linux:

```sh
git clone https://github.com/Orbit-Lua/orbitvim.git ~/.config/nvim
nvim
```

Windows, from `cmd.exe`:

```bat
git clone https://github.com/Orbit-Lua/orbitvim.git "%LOCALAPPDATA%\nvim"
nvim
```

Lazy installs the locked plugins on first start. Install language tools through Hangar. Install parsers with `:TSInstallAll`.

## Usage

Open Hangar with `:Hangar` or `<leader>us`. The leader key is Space.

| Key | Action |
| --- | --- |
| `1`–`6`, Tab / Shift-Tab | Select a tool category |
| `s` | Switch between the source buffer and all tools |
| Space | Toggle a runtime tool, with automatic installation when needed |
| `i` | Install without changing enablement |
| `[` / `]` | Reorder formatters or linters for a filetype |
| `o`, Enter, `za` | Expand or collapse a filetype group |
| `K` | Focus details |
| `?`, `g?` | Toggle help |
| `q`, Escape | Close |

Parsers and dependency packages support installation only. Enablement and order persist in `stdpath('data')/hangar.json`. See [Hangar](doc/hangar.md) for installation policy, status and recovery.

Other common actions:

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

For C#, put `dotnet` and `roslyn-language-server` on PATH. Install the server through Hangar. Restart Neovim after installation.

Roslyn prefers a single solution at the Git root that contains the current project. Use `:Roslyn target` to select one manually. `:DotnetManager` or `<leader>ud` opens build, test, package, EF Core and publish actions. `:DotnetDebug` and `:DotnetAttach` need `netcoredbg` and enabled `coreclr` tools.

SQLFluff formats and lints T-SQL. Linting runs on read, on save and when leaving Insert mode. See the [highlighting guide](doc/tsql-highlighting.md), [snippet catalog](doc/tsql-snippets.md) and [SQL conventions](doc/tsql-conventions.md).

`:PyrightReCreateStub` regenerates a package stub under the project's `typings` directory. It keeps the old stub until generation succeeds. Failed recovery reports the backup path.

## Configuration

Open personal settings with `:OrbitSettings` or `<leader>uc`. The writable default is `stdpath('data')/settings.json`. Startup reads legacy config settings while that destination is absent.

The command creates the destination only on explicit invocation. It copies legacy bytes unchanged and keeps the legacy file. Existing input is preserved, including invalid JSON. Enable `jsonls` for schema completion and validation.

For example, set these overrides in the generated file:

```json
{
  "editor": { "relativenumber": false, "shiftwidth": 4 },
  "hangar": { "width": 100, "missing_package_policy": "manual" }
}
```

Saving applies editor options, Hangar options and inlay hints. Server configuration, code lenses, initial tool priorities and notes settings need a restart. Invalid input keeps accepted values. See [settings](doc/settings.md) for precedence, explicit paths and rollback.

Set `notes.vault` to an Obsidian vault path to enable Markdown note integration.

## Supported platforms

CI runs the validation recipes on Linux. Run them locally on Windows before each push. The justfile uses `sh` on Linux and native `cmd.exe` on Windows.

On Windows, keep native Git before MSYS2 tools on PATH. Add MSYS2 UCRT64 GCC, Make and Bash for native builds. Keep explicit `shell` and `CC` choices when customizing the environment. OrbitVim selects available defaults otherwise.

On Windows, nvim-tree disables filesystem watchers. It refreshes on save, on entry and with `R`. `:ClearShada` keeps `main.shada` while removing temporary ShaDa files.
