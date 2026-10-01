describe("runtime.formatter.options", function()
  local originals

  before_each(function()
    originals = {
      state = package.loaded["tool.state"],
      order = package.loaded["tool.order"],
      plugin = package.loaded["plugins.formatter"],
      runtime = package.loaded["runtime.formatter"],
    }
  end)

  after_each(function()
    package.loaded["tool.state"] = originals.state
    package.loaded["tool.order"] = originals.order
    package.loaded["plugins.formatter"] = originals.plugin
    package.loaded["runtime.formatter"] = originals.runtime
  end)

  it(
    "filters disabled tools and returns fresh configured runtime options",
    function()
      local enabled = { sqlfluff = true, yaml = true }
      package.loaded["tool.state"] = {
        is_enabled = function(_, name)
          return enabled[name] == true
        end,
        get_order = function()
          return nil
        end,
      }
      package.loaded["tool.order"] = nil
      package.loaded["runtime.formatter"] = nil

      local options = require("runtime.formatter").options
      local first = options()
      assert.same({ "yamlfmt" }, first.formatters_by_ft.yaml)
      assert.is_true(vim.tbl_contains(first.formatters_by_ft.sql, "sqlfluff"))

      table.insert(first.formatters_by_ft.lua, "mutation")
      enabled.yaml = false
      local second = options()

      assert.is_false(vim.tbl_contains(second.formatters_by_ft.lua, "mutation"))
      assert.same({}, second.formatters_by_ft.yaml)
      assert.is_true(vim.tbl_contains(second.formatters_by_ft.sql, "sqlfluff"))
    end
  )
end)
