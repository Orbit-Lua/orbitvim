describe("plugin startup on first use", function()
  it(
    "keeps core setup eager and initializes plugins once on each demand path",
    function()
      local triggers = {
        "vim.cmd('Hangar'); require('hangar').close()",
        "vim.cmd('Lazy')",
        "require('hangar').open(); require('hangar').close()",
        "vim.cmd('colorscheme nvchad')",
        [[
local path = vim.fn.stdpath('data') .. '/startup-minified.lua'
vim.fn.writefile({string.rep('x', 3000)}, path)
local reads = 0
vim.api.nvim_create_autocmd('BufReadPre', {
  group=vim.api.nvim_create_augroup('StartupEarlierRead', {clear=true}),
  callback=function() reads = reads + 1 end,
})
vim.cmd.edit(path)
assert(vim.bo.filetype == 'bigfile', 'first file missed the large-file policy')
assert(reads == 1, 'existing file observer ran more than once')
]],
        [[
local ok, err = pcall(require, 'orbitvim_missing_startup_fixture')
assert(not ok and err:find('orbitvim_missing_startup_fixture', 1, true))
require('hangar').open()
require('hangar').close()
]],
      }
      for _, trigger in ipairs(triggers) do
        local session = require("tests.support.session").open(
          vim.fn.getcwd(),
          { headless = true }
        )
        local ok, err = pcall(function()
          session.exec([[
assert(not package.loaded.lazy, 'plugins initialized without demand')
assert(vim.fn.exists(':OrbitSettings') == 2, 'core command missing')
assert(vim.fn.exists(':Hangar') == 2, 'Hangar command missing')
local startup = require('core.startup')
startup.setup()
startup.setup()
vim.g.startup_demand_count = 0
vim.api.nvim_create_autocmd('User', {pattern='LazyDone', callback=function()
  vim.g.startup_demand_count = vim.g.startup_demand_count + 1
end})
vim.g.startup_demand_state = table.concat(vim.fn.readfile(vim.fn.stdpath('data') .. '/hangar.json'), '\n')
]])
          session.exec(trigger)
          session.exec([[
assert(package.loaded.lazy, 'demand did not initialize plugins')
require('core.startup').setup()
require('core.startup').setup()
require('hangar').open()
require('hangar').close()
assert(vim.g.startup_demand_count == 1, 'plugin initialization repeated or LazyDone was suppressed')
assert(#vim.api.nvim_get_autocmds({group='OrbitVimPluginStartup'}) == 0, 'startup subscriptions leaked')
local saved = table.concat(vim.fn.readfile(vim.fn.stdpath('data') .. '/hangar.json'), '\n')
assert(vim.g.startup_demand_state == saved, 'startup changed saved tool intent')
]])
          local health = session.exec("return orbitvim_session_health()")
          assert.same({}, health.errors)
        end)
        session.close()
        assert(ok, err)
      end
    end
  )
end)
