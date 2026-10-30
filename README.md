# OrbitVim

Neovim configuration for programming, SQL and Markdown, with persistent language tooling on Linux and Windows.

[![Validate OrbitVim](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml/badge.svg?branch=main)](https://github.com/Orbit-Lua/orbitvim/actions/workflows/validate.yml) [![Neovim](https://img.shields.io/badge/Neovim-0.12%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)

## Install

Install these requirements:

- Neovim 0.12+.
- Git.
- A C compiler for parser and native plugin builds.
- Tree-sitter CLI 0.26.1+ for parser builds.
- GNU Make for native plugin builds.
- Bash for native plugin builds.

Use network access for plugin and tool installation. Language servers can also need their language runtime or package manager. `:checkhealth mason` reports available installers.

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

See [startup behavior](doc/architecture.md#startup) for headless sessions and plugin activation.

## Usage

Start the editor:

```sh
nvim
```

Open Hangar with `:Hangar` or `<leader>us`. The leader key is Space.

Press `?` in Hangar for its keys. See [Hangar integration](doc/hangar.md) for OrbitVim settings, tool activation and state paths.

Common actions:

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

Tailwind LSP and ESLint diagnostics and fixes require project evidence. Package declarations or tool-specific configuration qualify; unrelated Git repositories do not. See [project conditions](doc/architecture.md#project-conditions) for workspace boundaries.

Use an ESLint template:

1. Copy a template from `lua/features/linter/config/template/` into the project as `eslint.config.mjs`.
2. Follow its dependency instructions.
3. Copy the template again when you need template updates.

Prepare C# tooling:

1. Install `roslyn-language-server` through Hangar.
2. Put `dotnet` and `roslyn-language-server` on PATH.
3. Restart Neovim after installation.

Roslyn prefers one solution at the Git root that contains the current project.
Use `:Roslyn target` to select a solution manually.
Open .NET workflows with `:DotnetManager` or `<leader>ud`.
Use its Command Line action for SDK suggestions and Tab completion.

`DapNew` and `DotnetDebug` reuse the saved startup project.
Without a selection, one runnable non-test project is selected automatically.
Multiple candidates open a picker.
A missing saved project requires an explicit replacement.
Selections persist under Neovim's state directory.
`DotnetDebug` and `DotnetAttach` require enabled `coreclr` tools and netcoredbg.
Use netcoredbg 3.2.0-1092 or newer for .NET 10 debugging.

SQLFluff formats and lints T-SQL. Linting runs on read, on save and when leaving Insert mode. See the [highlighting guide](doc/tsql-highlighting.md), [snippet catalog](doc/tsql-snippets.md) and [SQL conventions](doc/tsql-conventions.md).

`:PyrightReCreateStub` regenerates a package stub under the project's `typings` directory. It keeps the old stub until generation succeeds. Failed recovery reports the backup path.

## Configuration

Open personal settings with `:OrbitSettings` or `<leader>uc`. The default is `stdpath('data')/settings.json`.

The command creates the file only on explicit invocation. Existing input is preserved, including invalid JSON. Enable `jsonls` for schema completion and validation.

For example, set these overrides in the generated file:

```json
{
  "editor": { "relativenumber": false, "shiftwidth": 4 },
  "hangar": { "width": 100, "missing_package_policy": "manual" }
}
```

Saving applies editor options, Hangar options and inlay hints. Server configuration, code lenses, initial tool priorities and notes settings need a restart. Invalid input keeps accepted values. See [settings](doc/settings.md) for precedence, explicit paths and rollback.

Set `notes.vault` to an Obsidian vault path to enable Markdown note integration.

## Shared tasks

| Task | Owner |
| --- | --- |
| Plugin installation and loading | Lazy |
| Tool view, operations and saved tool state | hangar.nvim |
| Tool registry, settings and runtime adapters | OrbitVim |

See [shared-task boundaries](doc/architecture.md#shared-tasks) for terminal, navigation and display owners.

## Supported platforms

Linux and Windows are supported. See [testing](doc/testing.md) for contributor validation and platform recipes.

Prepare native builds on Windows:

1. Add MSYS2 UCRT64 GCC, Make and Bash to PATH.
2. Keep native Git before MSYS2 tools on PATH.
3. Keep explicit `shell` and `CC` choices when customizing the environment.

OrbitVim selects available defaults otherwise.

On Windows, nvim-tree disables filesystem watchers. It refreshes on save, on entry and with `R`. `:ClearShada` keeps `main.shada` while removing temporary ShaDa files.
