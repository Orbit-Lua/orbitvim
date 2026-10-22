describe("utils.cmp", function()
  local cmp_utils = require("utils.cmp")
  local original_actions

  before_each(function()
    original_actions = vim.tbl_extend("force", {}, cmp_utils.actions)
  end)

  after_each(function()
    cmp_utils.actions = original_actions
  end)

  describe("map", function()
    it(
      "uses value, function, and nil fallbacks when no action handles input",
      function()
        assert.equals("fallback", cmp_utils.map({}, "fallback")())
        assert.equals(
          "function fallback",
          cmp_utils.map({ "missing" }, function()
            return "function fallback"
          end)()
        )
        assert.is_nil(cmp_utils.map({})())
      end
    )

    it(
      "tries actions in order and stops after the first truthy result",
      function()
        local called = {}
        cmp_utils.actions._test_first = function()
          table.insert(called, "first")
        end
        cmp_utils.actions._test_second = function()
          table.insert(called, "second")
          return true
        end
        cmp_utils.actions._test_third = function()
          table.insert(called, "third")
          return true
        end

        local result = cmp_utils.map({
          "missing",
          "_test_first",
          "_test_second",
          "_test_third",
        })()

        cmp_utils.actions._test_first = nil
        cmp_utils.actions._test_second = nil
        cmp_utils.actions._test_third = nil
        assert.is_true(result)
        assert.same({ "first", "second" }, called)
      end
    )
  end)
end)
