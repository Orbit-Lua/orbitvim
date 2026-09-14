describe("config.tools", function()
  local tools = require("config.tools")

  local function assert_filetypes(name, definition, allow_empty)
    assert.is_table(definition.ft, name .. ".ft must be a list")
    assert.is_true(
      allow_empty or #definition.ft > 0,
      name .. ".ft must not be empty"
    )
    for _, filetype in ipairs(definition.ft) do
      assert.is_true(
        type(filetype) == "string" and filetype ~= "",
        name .. ".ft entries must be non-empty strings"
      )
    end
  end

  it("keeps runtime tool definitions well formed", function()
    for _, category in ipairs({ "lsp", "dap", "linter", "formatter" }) do
      assert.is_not_nil(next(tools[category]), category .. " must not be empty")

      for name, definition in pairs(tools[category]) do
        assert_filetypes(category .. "." .. name, definition, false)
        assert.equals(
          definition.mason and "mason" or "external",
          definition.source,
          category .. "." .. name .. " has an inconsistent source"
        )
      end
    end
  end)

  it("keeps parser and dependency definitions well formed", function()
    for name, definition in pairs(tools.parser) do
      assert_filetypes("parser." .. name, definition, true)
      assert.equals("treesitter", definition.source)
    end

    for name, definition in pairs(tools.package) do
      assert.is_true(
        definition.source == "mason" or definition.source == "external",
        "package." .. name .. " has an unsupported source"
      )
      assert.is_true(
        type(definition.role) == "string" and definition.role ~= "",
        "package." .. name .. " must declare its role"
      )
    end
  end)

  it(
    "references only registered tools in formatter and linter defaults",
    function()
      for _, category in ipairs({ "formatter", "linter" }) do
        for filetype, order in pairs(tools[category .. "_defaults"]) do
          local seen = {}
          for _, name in ipairs(order) do
            local definition = tools[category][name]
            assert.is_not_nil(
              definition,
              category .. " default references unknown tool " .. name
            )
            assert.is_nil(
              seen[name],
              category .. " default repeats tool " .. name
            )
            assert.is_true(
              vim.tbl_contains(definition.ft, filetype),
              name .. " does not support " .. filetype
            )
            seen[name] = true
          end
        end
      end
    end
  )
end)
