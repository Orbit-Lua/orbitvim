# Testing

OrbitVim validates changes through just recipes. CI runs the same recipes on Linux and Windows.

## Prerequisites

Install just, StyLua and Luacheck, in addition to the README runtime prerequisites. Core specs require the pinned Plenary, Nui and hangar.nvim sources. Integration specs also require SQLFluff and a JSON language server.

`just deps` installs the locked plugin revisions. It fails if `lazy-lock.json` changes. `just parsers` installs the C#, Lua, Markdown, SQL and vimdoc parsers. Integration specs execute them. Windows runtime filetype plugins also need the Lua and vimdoc parsers.

On Windows, use MSYS2 UCRT64 build tools with native Git. Preserve `LOCALAPPDATA` when Neovim runs through MSYS Make.

## Recipes

Run `just all` for every change. It checks formatting, runs Luacheck and runs the hermetic core specs. Some changes need another recipe:

| Change | Recipe |
| --- | --- |
| Parser, snippet, SQLFluff or JSON schema adapter | `just test-integration` |
| Native build | `just test-build` |
| Startup or plugin loading | `just smoke` |

Use `just --list` for recipe descriptions. Use `just test-spec <path>` to run one spec.

## Execution

Each spec runs in its own headless Neovim process. The runner fails a spec in these cases:

- The spec executes no test.
- A test fails, raises an error or is pending.
- Neovim shows an error message, a Lua error or `echoerr` output.

A test that expects a failure notification observes it explicitly. Other tests must not produce that notification.

## Fixtures

- Put fixtures below `vim.g.orbitvim_test_root` through `tests.helpers`.
- Keep installed plugin sources separate from writable build fixtures.
- Use the installed Nui rather than replacing its window API.

`just deps` and startup sessions prepare every locked plugin. They do not skip a plugin that needs a condition at startup. Inert `dotnet` and `roslyn-language-server` executables satisfy the Roslyn prerequisites without a .NET installation. An empty notes vault enables the notes plugin.

## Coverage

- Import feature specs without plugin access to guard declarations against activation and editor registrations.
- Execute parser queries and snippet expansions instead of inspecting their declarations.
- Keep schema references, cross-module derivation and persisted JSON coverage.
- Protect transaction ownership, identifier validation and value parameterization in SQL templates.
- Run each `sql` fence in [SQL conventions](tsql-conventions.md) through the integration corpus.
