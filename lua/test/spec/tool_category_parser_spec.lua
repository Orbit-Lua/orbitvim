describe("tool.category.parser", function()
  local parser

  before_each(function()
    package.loaded["tool.category.parser"] = nil
    package.loaded["nvim-treesitter"] = {
      get_installed = function()
        return { "lua", "python" }
      end,
      install = function() end,
    }
    parser = require("tool.category.parser")
  end)

  after_each(function()
    package.loaded["nvim-treesitter"] = nil
    package.loaded["tool.category.parser"] = nil
  end)

  it("reports installed and missing parsers", function()
    assert.same(
      { "installed", "DiagnosticOk" },
      { parser.entry_status({ name = "lua", meta = {} }) }
    )
    assert.same(
      { "not installed", "DiagnosticError" },
      { parser.entry_status({ name = "tsx", meta = {} }) }
    )
  end)

  it(
    "summarizes parser installation without exposing toggle behavior",
    function()
      assert.same(
        { total = 3, installed = 2, missing = 1 },
        parser.summary({ lua = {}, python = {}, tsx = {} })
      )
      assert.is_false(parser.capabilities.toggle)
      assert.is_true(parser.capabilities.install)
    end
  )
end)
