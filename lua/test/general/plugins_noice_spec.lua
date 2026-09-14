describe("plugins.ui.noice", function()
  it(
    "routes formatter and LSP progress notifications to the bottom-right mini view",
    function()
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
      assert.same("mini", formatter_route.view)
      for _, state in ipairs({ "progress", "done", "error" }) do
        assert.is_true(formatter_route.filter.cond({
          opts = { orbit_formatter = state },
        }))
      end

      assert.same({ row = -3, col = "100%" }, opts.views.mini.position)
      assert.same("mini", opts.lsp.progress.view)

      package.loaded["plugins.ui.noice"] = nil
    end
  )
end)
