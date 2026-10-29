describe("features.formatter.runtime.options", function()
  local originals

  before_each(function()
    originals = {
      state = package.loaded["hangar.state"],
      order = package.loaded["hangar.order"],
      plugin = package.loaded["features.formatter.spec"],
      runtime = package.loaded["features.formatter.runtime"],
    }
  end)

  after_each(function()
    package.loaded["hangar.state"] = originals.state
    package.loaded["hangar.order"] = originals.order
    package.loaded["features.formatter.spec"] = originals.plugin
    package.loaded["features.formatter.runtime"] = originals.runtime
  end)

  -- Registered after the spec's own hook, so setup follows any module reset.
  before_each(function()
    require("tests.helpers").configure_tool()
  end)

  it(
    "filters disabled tools and returns fresh configured runtime options",
    function()
      local enabled = { sqlfluff = true, yaml = true }
      package.loaded["hangar.state"] = {
        is_enabled = function(_, name)
          return enabled[name] == true
        end,
        get_order = function()
          return nil
        end,
      }
      package.loaded["hangar.order"] = nil
      package.loaded["features.formatter.runtime"] = nil

      local options = require("features.formatter.runtime").options
      local first = options()
      assert.same({ "yamlfmt" }, first.formatters_by_ft.yaml)
      assert.is_true(vim.tbl_contains(first.formatters_by_ft.sql, "sqlfluff"))

      local timeout = first.default_format_opts.timeout_ms
      first.default_format_opts.timeout_ms = timeout + 1
      enabled.yaml = false
      local second = options()

      assert.equals(timeout, second.default_format_opts.timeout_ms)
      assert.same({}, second.formatters_by_ft.yaml)
      assert.is_true(vim.tbl_contains(second.formatters_by_ft.sql, "sqlfluff"))
      enabled.yaml = true
      assert.same({ "yamlfmt" }, options().formatters_by_ft.yaml)
    end
  )
end)
