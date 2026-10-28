describe("Snacks large-file policy", function()
  it(
    "keeps automatic lint and parsing disabled for detected large files",
    function()
      local session = require("scripts.tests.session").open(vim.fn.getcwd(), {})
      local ok, err = pcall(function()
        session.exec(
          [[
local path = ...
vim.fn.writefile({string.rep('x', 3000)}, path)
vim.cmd.edit(path)
assert(vim.bo.filetype == 'bigfile', 'Snacks did not detect the minified file')
local starts, runs = 0, 0
local start = vim.treesitter.start
vim.treesitter.start = function() starts = starts + 1 end
require('features.treesitter.runtime').start()
vim.treesitter.start = start
assert(starts == 0, 'custom parser activation bypassed the bigfile policy')
local lint = require('lint')
lint.try_lint = function() runs = runs + 1 end
require('features.linter.runtime').setup({
  events={'BufWritePost'}, linters={}, linters_by_ft={['*']={'probe'}},
})
vim.api.nvim_exec_autocmds('BufWritePost', {buffer=0})
local complete = false
vim.defer_fn(function() complete = true end, 350)
assert(vim.wait(3000, function() return complete end, 10))
assert(runs == 0, 'automatic lint bypassed the bigfile policy')
]],
          { session.root .. "/project/minified.lua" }
        )
      end)
      session.close()
      assert(ok, err)
    end
  )
end)
