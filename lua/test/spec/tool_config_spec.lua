describe("tool.config", function()
  local config = require("tool.config")

  it(
    "automatically installs missing Mason packages when enabling tools",
    function()
      assert.equals("auto", config.missing_package_policy)
    end
  )

  it("defines the category navigation order and labels", function()
    local categories = {
      "lsp",
      "dap",
      "linter",
      "formatter",
      "parser",
      "package",
    }

    assert.same(categories, config.tool_categories)
    for _, category in ipairs(categories) do
      assert.is_true(
        type(config.cat_label[category]) == "string"
          and config.cat_label[category] ~= "",
        category .. " must have a navigation label"
      )
    end
  end)
end)
