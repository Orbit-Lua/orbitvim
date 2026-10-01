describe("tool.category.parser", function()
  local parser
  local original_parser
  local original_handler

  before_each(function()
    original_parser = package.loaded["nvim-treesitter"]
    original_handler = package.loaded["tool.category.parser"]
    package.loaded["tool.category.parser"] = nil
    package.loaded["nvim-treesitter"] = {
      get_installed = function()
        return { "lua", "python" }
      end,
      install = function()
        return {
          await = function(_, callback)
            callback(nil, true)
          end,
        }
      end,
    }
    parser = require("tool.category.parser")
  end)

  after_each(function()
    package.loaded["nvim-treesitter"] = original_parser
    package.loaded["tool.category.parser"] = original_handler
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

  it("summarizes installed and missing parsers", function()
    assert.same(
      { total = 3, installed = 2, missing = 1 },
      parser.summary({ lua = {}, python = {}, tsx = {} })
    )
  end)

  it(
    "reports success only when the async installer confirms installation",
    function()
      local results = {}
      assert.is_true(parser.install("lua", function(ok, err)
        table.insert(results, { ok, err })
      end))
      assert.is_true(vim.wait(1000, function()
        return #results == 1
      end))
      assert.same({ true }, results[1])
    end
  )

  it("propagates parser install failures and rejects missing tasks", function()
    package.loaded["nvim-treesitter"].install = function()
      return {
        await = function(_, callback)
          callback(nil, false)
        end,
      }
    end
    local failed
    assert.is_true(parser.install("python", function(ok, err)
      failed = { ok, err }
    end))
    assert.is_true(vim.wait(1000, function()
      return failed ~= nil
    end))
    assert.is_false(failed[1])
    assert.equals("installation failed", failed[2])

    package.loaded["nvim-treesitter"].install = function() end
    local missing
    assert.is_false(parser.install("lua", function(ok, err)
      missing = { ok, err }
    end))
    assert.is_false(missing[1])
    assert.is_truthy(missing[2])
  end)
end)
