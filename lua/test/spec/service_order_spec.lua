describe("service.order", function()
  local order
  local state
  local previous_lua_order
  local previous_stylua_enabled

  before_each(function()
    package.loaded["service.order"] = nil
    package.loaded["service.state"] = nil
    state = require("service.state")
    order = require("service.order")
    previous_lua_order = vim.deepcopy(state.get().formatter_order.lua)
    previous_stylua_enabled = state.is_enabled("formatter", "stylua")
  end)

  after_each(function()
    state.set_order("formatter", "_test_ft_order_", nil)
    state.set_order("formatter", "lua", previous_lua_order)
    state.set_enabled("formatter", "stylua", previous_stylua_enabled)
  end)

  it("applies saved order to an existing runtime list", function()
    state.set_order("formatter", "_test_ft_order_", { "a", "b" })

    assert.same(
      { "a", "b", "z" },
      order.names_for_ft("formatter", "_test_ft_order_", { "b", "z", "a" })
    )
  end)

  it(
    "filters disabled managed services but preserves unknown runtime entries",
    function()
      state.set_order("formatter", "lua", { "stylua" })
      state.set_enabled("formatter", "stylua", false)

      assert.same(
        { "external_formatter" },
        order.enabled_names_for_ft(
          "formatter",
          "lua",
          { "stylua", "external_formatter" }
        )
      )
    end
  )
end)
