# AGENTS.md

## Project Overview

OrbitVim is a modular Neovim configuration written in Lua. It bootstraps
`lazy.nvim`, loads plugin specs from `lua/plugins/`, applies Nv UI/base46
configuration, and exposes a custom Service Manager for LSP, DAP, formatter, and
linter services.

Primary technologies:

- Neovim Lua APIs
- `lazy.nvim` plugin management
- Nv UI and `nv-base46` theming
- Mason package management
- `nvim-lspconfig`, `conform.nvim`, `nvim-lint`, and `nvim-dap`
- Plenary/Busted tests
- Stylua and Luacheck

## Repository Layout

- `init.lua` bootstraps `lazy.nvim`, imports `lua/plugins/`, and calls
  `require("config.starter").setup()`.
- `lua/config/starter.lua` owns startup orchestration after Lazy setup.
- `lua/config/defaults.lua` sets baseline editor defaults and prepends Mason
  `bin` to `PATH`.
- `lua/config/options.lua`, `lua/config/keymaps.lua`, `lua/config/autocmds.lua`,
  `lua/config/events.lua`, and `lua/config/filetypes.lua` contain user-facing
  editor behavior.
- `lua/nvconfig.lua` merges defaults with `lua/config/nvui.lua` for Nv UI and
  `nv-base46`.
- `lua/config/nvui.lua` owns theme, highlights, Mason package config,
  statusline, tabline, and terminal UI settings.
- `lua/config/theme.lua` implements the local base46 theme picker and persists
  theme changes into `lua/config/nvui.lua`.
- `lua/config/services.lua` is the source of truth for managed LSP, DAP,
  formatter, and linter services.
- `lua/config/packages.lua` derives Mason packages, LSP server names, and
  Treesitter parser lists from the service registry.
- `lua/config/formatter/init.lua` configures `conform.nvim`.
- `lua/config/linter/init.lua` configures `nvim-lint`.
- `lua/plugins/` contains lazy.nvim specs grouped by feature area.
- `lua/plugins/lsp/` contains LSP registration, diagnostics, capabilities,
  keymaps, and per-language server configuration.
- `lua/plugins/debugger/` contains DAP plugins and per-language debug config.
- `lua/service/` implements Service Manager UI, persistent state, actions,
  rendering, Mason integration, run-error display, and formatter/linter ordering.
- `lua/utils/` contains shared helpers. Reuse these before adding new helper
  modules.
- `lua/cmds/` contains custom commands loaded during startup.
- `lua/test/spec/` contains Plenary tests.
- `scripts/tests/minimal.vim` is the headless test bootstrap.

## Setup Commands

Install runtime tools expected by development commands:

```bash
# Use your system package manager, Mason, or luarocks as appropriate.
stylua --version
luacheck --version
nvim --version
```

Open Neovim once to let `init.lua` bootstrap `lazy.nvim` and install plugins:

```bash
nvim
```

After plugin installation, install all configured Treesitter parsers from
Neovim:

```vim
:TSInstallAll
```

The test bootstrap expects `plenary.nvim` under Neovim's lazy data directory,
which is created by the normal plugin install flow.

## Development Workflow

- Add plugin specs under the closest feature file in `lua/plugins/`.
- Keep language-service definitions in `lua/config/services.lua`; do not
  duplicate Mason package lists by hand unless the package is intentionally an
  extra in `lua/config/packages.lua`.
- Put formatter behavior in `lua/config/formatter/init.lua`.
- Put linter behavior in `lua/config/linter/init.lua`.
- Keep `lua/config/` modules focused on declaring options and user-facing
  configuration. Move calculations, autocmd/event registration, runtime mutation,
  and plugin setup glue into the owning utility, plugin setup, or domain module
  instead.
- Put shared behavior in an existing `lua/utils/` module when one matches the
  domain.
- For Service Manager behavior, update `lua/service/` and add focused tests in
  `lua/test/spec/`.
- For startup changes, inspect the load order in `init.lua` and
  `lua/config/starter.lua` before editing.

Useful commands:

```bash
make fmt
make lint
make test
make all
```

Startup smoke test:

```bash
nvim --headless "+qall"
```

## Testing Instructions

Run the full validation suite before finishing changes:

```bash
make all
```

This runs:

- `stylua lua/ --config-path=.stylua.toml`
- `luacheck lua --globals vim`
- `nvim --headless --noplugin -u scripts/tests/minimal.vim -c "PlenaryBustedDirectory lua/test/spec/ {minimal_init = 'scripts/tests/minimal.vim'}"`

For edits to `init.lua`, `lua/config/starter.lua`, Lazy bootstrap behavior,
plugin loading, startup events, or other startup paths, also run:

```bash
nvim --headless "+qall"
```

Run a single spec with:

```bash
nvim --headless --noplugin -u scripts/tests/minimal.vim \
  -c "PlenaryBustedFile lua/test/spec/service_state_spec.lua {minimal_init = 'scripts/tests/minimal.vim'}"
```

Add or update focused tests for:

- shared utilities in `lua/utils/`
- Service Manager state, rendering data, actions, Mason integration, and service
  ordering
- service registry derivation in `lua/config/packages.lua`
- headless logic that can regress without opening a UI

## Code Style

- Follow `.stylua.toml`: two-space indentation, Unix line endings, and automatic
  quote preference.
- Follow `.editorconfig`: UTF-8, final newline, trimmed trailing whitespace.
- Keep Lua modules small and aligned with the existing feature areas.
- Keep option modules clean and declarative; avoid mixing option tables with
  unrelated calculations, event wiring, or runtime side effects.
- Prefer structured Lua tables and Neovim APIs over ad hoc string handling.
- Prefer existing helpers in `lua/utils/` before creating new modules.
- Keep plugin specs grouped by feature area under `lua/plugins/`.
- Use comments only where they clarify non-obvious behavior.
- Avoid broad rewrites when a focused change is enough.

## Service Registry Rules

- `lua/config/services.lua` is canonical for managed services.
- Each service entry should include the service name, Mason package when Mason
  manages it, and filetypes.
- DAP entries may use `mason = nil` when the adapter is external, such as Python
  `debugpy` from a virtual environment.
- Formatter and linter defaults that require ordering belong in
  `formatter_defaults` and `linter_defaults`.
- `lua/config/packages.lua` derives `lsp_servers` and
  `mason_ensure_installed`; keep derivation deterministic and sorted.
- Service Manager persisted state must tolerate missing, invalid, or stale
  `service.json` data.

## Build and Deployment

This repository is a Neovim configuration, not a compiled application. There is
no production build step. The closest equivalent is:

```bash
make all
nvim --headless "+qall"
```

Plugin versions are pinned in `lazy-lock.json`. Do not churn that file unless
the task intentionally updates plugin versions.

## Security and Safety

- Do not commit secrets, local tokens, machine-specific paths, or generated
  credentials.
- Treat files under `lua/config/*/template/` as reusable local templates; avoid
  embedding user-private values.
- Be careful with commands that delete files. The Windows-only `ClearShada`
  command deliberately skips `main.shada`; preserve that behavior.
- Do not overwrite user state in Neovim data directories from tests unless a
  test explicitly redirects paths such as `vim.g.service_state_path`.

## Pull Request Checklist

- Run `make all`.
- Run `nvim --headless "+qall"` when startup paths changed.
- Add or update focused tests for changed headless logic.
- Keep docs in sync when commands, service ownership, or repository layout
  change.
