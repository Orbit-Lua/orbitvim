describe("Snacks redraw recovery", function()
  it(
    "ignores stale windows while retaining unexpected failures after repeated setup",
    function()
      local calls, failure = 0, "Invalid window id: 77"
      package.loaded.snacks = {
        setup = function() end,
        util = {
          redraw_range = function()
            calls = calls + 1
            error(failure)
          end,
        },
      }
      local runtime = require("runtime.ui")
      runtime.setup_snacks({})
      runtime.setup_snacks({})
      assert.has_no.errors(function()
        require("snacks").util.redraw_range()
      end)
      assert.equals(1, calls)
      failure = "unexpected renderer failure"
      local ok, err = pcall(require("snacks").util.redraw_range)
      assert.is_false(ok)
      assert.is_truthy(err:find(failure, 1, true))
    end
  )
end)
