describe("features.messages.spec", function()
  local original_noice

  before_each(function()
    original_noice = package.loaded["features.messages.spec"]
    package.loaded["features.messages.spec"] = nil
  end)

  after_each(function()
    package.loaded["features.messages.spec"] = original_noice
  end)

  it("routes formatter lifecycle notifications to the mini view", function()
    local opts = require("features.messages.spec")[1].opts()
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
    assert.is_false(formatter_route.filter.cond({ opts = {} }))
  end)
end)
