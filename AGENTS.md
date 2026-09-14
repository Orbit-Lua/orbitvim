# AGENTS Instructions

## Scope

This repository is a personal Neovim configuration, not a general-purpose
distribution. Keep changes explicit, declarative, and close to the owning
plugin or subsystem. Minimum supported Neovim version: 0.11.3.

## Ownership

- lua/config/tools.lua is the single source of truth for development tools.
- lua/config/packages.lua derives LSP, Mason, Treesitter, formatter, and
  linter consumer data. Do not duplicate those inventories in plugin specs.
- Neovim owns LSP activation; Mason owns supported external tool installation;
  Conform owns formatting; nvim-lint owns linting; nvim-dap owns debugging;
  nvim-treesitter owns parsers.
- Keep formatter-specific code in lua/config/formatter/ and linter-specific
  code in lua/config/linter/.
- lua/utils/sqlfluff.lua owns SQLFluff project discovery.
  lua/utils/treesitter.lua owns custom T-SQL runtime behavior; query extensions
  under after/queries/ are intentional project functionality.
- Do not add generic utility facades or parallel persisted tool/lifecycle state.

## Startup and dependencies

Startup begins at init.lua and continues through config.starter. The lazy.nvim
bootstrap must use the revision pinned in lazy-lock.json and fail fast when
clone or checkout fails. Avoid new dependencies on private plugin APIs; verify
the pinned revision before changing an existing private API.

Keep lazy-lock.json unchanged unless a plugin is intentionally added, removed,
or upgraded. Do not regenerate it as incidental churn.

## Platform and safety

- Preserve Windows support and select shell executables with
  vim.fn.executable() capability checks.
- Preserve the Windows ClearShada safeguard in lua/cmds/system.lua.
- Do not broaden shada deletion behavior without a focused regression test.
- Preserve unrelated dirty-worktree changes. Do not use destructive Git recovery
  commands unless explicitly requested.
- Do not print or commit secrets, machine-specific state, or generated plugin data.

## Tests and validation

Run make all for behavioral changes. It checks formatting, Luacheck, suite
validation, and the hermetic core and general tests.

The core and general suites must remain deterministic and network-free. Run
make test-general for general runtime or plugin behavior, and run
make test-integration after preparing parsers with:

```sh
nvim --headless -u init.lua -l lua/test/install_parsers.lua
```

Integration tests cover external SQLFluff and Treesitter seams and are not part
of the default make all or regular CI test path. make test-all runs every suite.
Run nvim --headless "+qall" when changing startup, plugin loading, shell
initialization, or core plugin specs.

When fixing a regression, update the closest focused test. In the final report
state one of Tests added, Tests updated, or No tests added.

## Documentation and change quality

Keep user workflows and public behavior in README.md; keep agent ownership,
safety, and validation rules here; keep domain details in doc/. Remove dead
configuration when a feature is removed. Prefer small ownership surfaces and
reviewable changes.
