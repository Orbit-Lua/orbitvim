describe("Harpoon shortcut activation", function()
  it(
    "loads on the first add shortcut and opens the same list through its menu shortcut",
    function()
      local session = require("tests.support.session").open(
        vim.fn.getcwd(),
        { file = "fixture.lua" }
      )
      local ok, err = pcall(function()
        session.exec([[
assert(package.loaded.harpoon == nil, 'Harpoon loaded before its shortcut')
local function press(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
end
press('<Space>ba')
local harpoon = require('harpoon')
assert(harpoon:list():length() == 1, 'first shortcut did not add exactly once')
assert(harpoon:list().items[1].value == 'fixture.lua')
press('<C-e>')
assert(vim.bo.filetype == 'harpoon', 'menu shortcut did not open the list')
local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
assert(content:find('fixture.lua', 1, true))
harpoon.ui:close_menu()
]])
        local health = session.exec("return orbitvim_session_health()")
        assert.same({}, health.errors)
      end)
      session.close()
      assert(ok, err)
    end
  )
end)
