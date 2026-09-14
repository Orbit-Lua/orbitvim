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
          definition.source
        )
      end
    end
  end)

  it("keeps parser and dependency definitions well formed", function()
    for name, definition in pairs(tools.parser) do
      assert_filetypes("parser." .. name, definition, true)
      assert.equals("treesitter", definition.source)
    end
    for _, definition in pairs(tools.package) do
      assert.is_true(
        definition.source == "mason" or definition.source == "external"
      )
      assert.is_true(
        type(definition.role) == "string" and definition.role ~= ""
      )
    end
  end)

  it(
    "keeps critical routing invariants aligned with runtime behavior",
    function()
      assert.is_not_nil(tools.formatter.yamlfmt)
      assert.is_nil(tools.formatter.yaml)
      assert.is_true(
        vim.tbl_contains(tools.formatter.deno_fmt.ft, "typescript")
      )
      assert.is_true(vim.tbl_contains(tools.formatter.deno_fmt.ft, "jsonc"))
      assert.is_true(vim.tbl_contains(tools.linter.eslint_d.ft, "jsx"))
      assert.is_nil(tools.linter.luacheck.mason)
      assert.same({ "sql", "mysql", "plsql" }, tools.linter.sqlfluff.ft)
    end
  )
end)
