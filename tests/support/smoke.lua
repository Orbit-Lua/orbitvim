local repository = vim.fn.getcwd()
package.path = repository .. "/?.lua;" .. package.path
for _, options in ipairs({
  {},
  { file = "fixture.lua" },
  { directory = true },
  { file = "fixture.cs", roslyn = true },
}) do
  local session = require("tests.support.session").open(repository, options)
  local ok, err = pcall(function()
    session.exec([[
if package.loaded.lazy then
  vim.api.nvim_exec_autocmds('InsertEnter', {})
  vim.cmd('Hangar')
  require('hangar').close()
end
]])
    session.exec("return true")
    if options.roslyn then
      session.exec([[
assert(package.loaded.roslyn and package.loaded['roslyn.config'], 'required Roslyn startup branch did not execute')
local initialization = vim.lsp.config.roslyn.on_init
assert(type(initialization) == 'table' and #initialization > 0, 'Roslyn initialization hooks are missing')
for _, hook in ipairs(initialization) do assert(type(hook) == 'function') end
assert(type(vim.lsp.config.roslyn.on_attach) == 'function', 'OrbitVim attachment hook is missing')
]])
    end
    local health = session.exec("return orbitvim_session_health()")
    assert(#health.errors == 0, table.concat(health.errors, "\n"))
  end)
  session.close()
  assert(ok, err)
end
