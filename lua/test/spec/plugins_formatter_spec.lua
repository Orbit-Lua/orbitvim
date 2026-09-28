describe("plugins.formatter", function()
  it("returns fresh formatter options on each lazy setup", function()
    local saved_state = package.loaded["tool.state"]
    local saved_order = package.loaded["tool.order"]
    package.loaded["tool.state"] = {
      is_enabled = function()
        return true
      end,
    }
    package.loaded["tool.order"] = {
      enabled_names_for_ft = function(_, _, names)
        return vim.deepcopy(names)
      end,
    }
    package.loaded["plugins.formatter"] = nil

    local opts = require("plugins.formatter")[1].opts
    local first = opts()
    table.insert(first.formatters_by_ft.lua, "mutation")
    local second = opts()

    assert.is_false(vim.tbl_contains(second.formatters_by_ft.lua, "mutation"))
    package.loaded["tool.state"] = saved_state
    package.loaded["tool.order"] = saved_order
    package.loaded["plugins.formatter"] = nil
  end)
end)
