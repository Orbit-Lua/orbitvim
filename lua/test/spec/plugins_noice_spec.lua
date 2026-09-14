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
      assert.same("formatter_progress", formatter_route.view)
      assert.is_true(formatter_route.filter.cond({
        opts = { title = "formatter" },
      }))

      local formatter_view = opts.views.formatter_progress
      assert.same("mini", formatter_view.view)
      assert.same("{data.icon} ", formatter_view.format[1][1])
      assert.same("NoiceLspProgressSpinner", formatter_view.format[1].hl_group)
      assert.same("{message}", formatter_view.format[2][1])
      assert.same("NoiceLspProgressTitle", formatter_view.format[2].hl_group)
      assert.same("{title} ", formatter_view.format[3][1])
      assert.same("NoiceLspProgressClient", formatter_view.format[3].hl_group)
      assert.same({ row = -3, col = "100%" }, opts.views.mini.position)
      assert.same("mini", opts.lsp.progress.view)

      package.loaded["plugins.ui.noice"] = nil
    end
  )
end)
