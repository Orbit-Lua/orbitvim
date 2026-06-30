# AGENTS Instructions

This file is the AI operating contract for OrbitVim. It exists so AI
assistants can make changes without rediscovering the repository from scratch,
while preserving user data, local state, and the project's existing style.

## Project Boundary

OrbitVim is a personal Neovim configuration built directly on `lazy.nvim`. It
keeps used Nv UI/base46 behavior through the `Orbit-Lua/nv-ui` and
`Orbit-Lua/nv-base46` forks.

Important entrypoints and ownership boundaries:

- `init.lua` bootstraps `lazy.nvim`, imports `lua/plugins/`, and calls
  `require("config.starter").setup()`
- `lua/config/starter.lua` owns startup orchestration after lazy.nvim setup
- `lua/nvconfig.lua` is the config entrypoint consumed by `nv-ui` and
  `nv-base46`
- `lua/config/nvui.lua` contains Nv UI/base46 theme, highlight, Mason,
  statusline, tabline, and terminal settings
- `lua/config/theme.lua` implements the local base46 theme picker and persists
  theme changes into `lua/config/nvui.lua`
- `lua/config/services.lua` is the canonical registry for managed LSP, DAP,
  formatter, and linter tools
- `lua/config/packages.lua` derives Mason packages and LSP server lists from
  the service registry
- `lua/plugins/` contains lazy.nvim specs grouped by feature area
- `lua/service/` implements Service Manager UI, state, actions, rendering,
  Mason integration, and formatter/linter ordering
- `lua/utils/` contains shared helpers only; startup lifecycle belongs in
  `lua/config/starter.lua`
- `lua/cmds/` contains custom commands loaded during startup
- `lua/test/spec/` contains Plenary tests
- `scripts/tests/minimal.vim` is the headless test bootstrap

`lua/plugins/init.lua` is intentionally empty. Lazy imports the `plugins`
namespace and discovers the feature-specific spec files directly.

## Default Working Agreement

- Inspect `git status --short` before editing.
- Read the relevant files before changing behavior. Do not rely on stale
  assumptions from older NvChad layouts.
- Prefer small, localized changes that preserve the current module boundaries.
- Keep `lua/config/services.lua` as the single source of truth for managed
  services.
- Reuse helpers from `lua/utils/` before adding new helper modules.
- Treat Service Manager state and Neovim data directories as user data.
- Do not overwrite unrelated local changes. If an unrelated file is dirty,
  leave it alone.
- Do not edit `lazy-lock.json` unless the task intentionally changes plugin
  versions or plugin sources.
- Do not assume Mason installs project-local dependencies such as Python
  `debugpy` or Prisma packages in `node_modules`.
- Do not assume `:ServiceManager` exists before Lazy finishes loading.

## Build And Test

Run `make all` before finishing changes.

`make all` expands to:

- `make fmt`, which runs `stylua lua/ --config-path=.stylua.toml`
- `make lint`, which runs `luacheck lua --globals vim` and uses
  `luacheck.bat` on Windows
- `make test`, which runs headless Plenary tests through
  `scripts/tests/minimal.vim`

Requirements:

- `stylua`, `luacheck`, and `nvim` must be available
- Plugins must be synced, including `plenary.nvim` in Neovim's lazy data
  directory

If `make test` cannot load plugins, run `:Lazy sync` in Neovim and retry.

For edits to `init.lua`, `lua/config/starter.lua`, plugin bootstrap, or other
startup paths, also run:

```bash
nvim --headless "+qall"
```

## Development Style

- Follow `.stylua.toml`: 2-space indentation, Unix line endings, 80-column
  target, and automatic quote preference.
- Keep Lua modules small and aligned with the existing feature boundaries.
- Use structured Lua tables and Neovim APIs instead of ad hoc string handling
  when the codebase already has a safer helper or parser.
- Keep plugin specs grouped by feature area under `lua/plugins/`.
- Keep managed service metadata in `lua/config/services.lua`; derive package
  and runtime lists from that registry.
- Add or update tests for shared utilities, Service Manager state/order logic,
  service registry derivation, and behavior that can run headlessly.
- Use concise comments only when they explain non-obvious behavior.

## Behavioral Boundaries

- Do not delete, reset, or rewrite user data outside this repository.
- Do not remove Neovim data, state, ShaDa, Mason, lazy.nvim, plugin data, or
  `service.json` files unless explicitly asked.
- Do not run destructive Git commands such as `git reset --hard` or
  `git checkout --` unless explicitly asked.
- Do not revert user changes to resolve conflicts. Work with the current
  worktree, or ask only when the changes make the task impossible.
- Do not rewrite unrelated files while pursuing a narrow task.
- Do not run recursive delete or move commands outside an explicitly intended
  repository path.
- Do not change runtime dependency policy silently. Document any new external
  executable, Mason package, project-local package, or platform requirement.

## Runtime Constraints

- `:ServiceManager` is registered after the `User LazyDone` event.
- Service Manager state is persisted outside the repo in Neovim's data
  directory as `service.json`, unless `vim.g.service_state_path` overrides it
  in tests.
- Enabling a missing Mason-backed service can auto-install its package because
  `missing_package_policy` is `auto`.
- Formatter and linter order is persisted per filetype for Service Manager.
- Formatting is manual; format-on-save is disabled.
- Python debugging requires `debugpy` in the active virtual environment.
- .NET support requires the `dotnet` executable.
- Prisma formatting expects project-local Node dependencies.
- Obsidian integration only loads when `~/OneDrive/Knowledge_Base` exists.
- Windows behavior includes `:ClearShada`, CRLF diagnostic normalization, a
  Windows-specific LuaSnip build command, and a forked DAP plugin for
  breakpoint behavior.
- `nvim <dir>` changes cwd to that directory and removes the initial empty
  buffer.

## Change Validation Expectations

- Shared utility changes should have focused tests under `lua/test/spec/`.
- Service Manager changes should cover state loading, ordering, category
  behavior, and runtime derivation when possible.
- Registry changes should update or add tests for `config.services` and
  `config.packages`.
- Startup or bootstrap changes require both `make all` and
  `nvim --headless "+qall"`.
- UI-only changes should still run `make all`; add screenshots or manual notes
  only when layout or highlight behavior cannot be tested headlessly.

## Communication Defaults

- Report what changed, what validation ran, and any skipped checks.
- Mention files by path when explaining behavior.
- Keep summaries concise and action-oriented.
- Surface runtime caveats early, especially when a feature depends on external
  tools, user-local state, or platform-specific behavior.
