describe("plugins.ui.noice", function()
  it("routes formatter lifecycle notifications to the mini view", function()
    package.loaded["plugins.ui.noice"] = nil
    local opts = require("plugins.ui.noice")[1].opts
    local formatter_route

    for _, route in ipairs(opts.routes) do
      if route.filter.event == "notify" and route.filter.cond then
        formatter_route = route
        break
      end
    end

    assert.is_not_nil(formatter_route)
    assert.same("formatter_progress", formatter_route.view)
    for _, state in ipairs({ "progress", "done", "error" }) do
      assert.is_true(formatter_route.filter.cond({
        opts = { orbit_formatter = state },
      }))
    end

    local view = opts.views.formatter_progress
    assert.same("mini", view.view)
    assert.same("{data.orbit_formatter_icon} ", view.format[1][1])
    assert.same("NoiceLspProgressSpinner", view.format[1].hl_group)
    assert.same("{message}", view.format[2][1])
    assert.same("NoiceLspProgressTitle", view.format[2].hl_group)

    package.loaded["plugins.ui.noice"] = nil
  end)
end)
