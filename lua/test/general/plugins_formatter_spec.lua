describe("plugins.formatter", function()
  it("delegates the format key to the formatter runtime", function()
    local called = false
    local original = package.loaded["config.formatter.runtime"]
    package.loaded["config.formatter.runtime"] = {
      format = function()
        called = true
      end,
    }
    package.loaded["plugins.formatter"] = nil

    require("plugins.formatter")[1].keys[1][2]()

    assert.is_true(called)
    package.loaded["config.formatter.runtime"] = original
    package.loaded["plugins.formatter"] = nil
  end)
end)
