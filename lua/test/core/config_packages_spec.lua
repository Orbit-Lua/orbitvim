describe("config.packages", function()
  local packages = require("config.packages")
  local tools = require("config.tools")

  local function sorted_keys(tbl)
    local result = vim.tbl_keys(tbl)
    table.sort(result)
    return result
  end

  local function derive_by_ft(category)
    local routed = {}
    for name, definition in pairs(tools[category]) do
      for _, filetype in ipairs(definition.ft) do
        routed[filetype] = routed[filetype] or {}
        table.insert(
          routed[filetype],
          { name = name, order = definition.order or 100 }
        )
      end
    end

    local result = {}
    for filetype, entries in pairs(routed) do
      table.sort(entries, function(a, b)
        if a.order == b.order then
          return a.name < b.name
        end
        return a.order < b.order
      end)
      result[filetype] = {}
      for _, entry in ipairs(entries) do
        table.insert(result[filetype], entry.name)
      end
    end
    return result
  end

  it("derives the sorted LSP server list from the tool registry", function()
    assert.same(sorted_keys(tools.lsp), packages.lsp_servers)
  end)

  it("derives a sorted unique Mason package list from every owner", function()
    local expected = {}
    for _, category in ipairs({ "lsp", "dap", "linter", "formatter" }) do
      for _, definition in pairs(tools[category]) do
        if definition.mason then
          expected[definition.mason] = true
        end
      end
    end
    for name, definition in pairs(tools.package) do
      if definition.source == "mason" then
        expected[name] = true
      end
    end
    assert.same(sorted_keys(expected), packages.mason_ensure_installed)
  end)

  it(
    "derives parser, formatter, and linter routing from the registry",
    function()
      assert.same(
        sorted_keys(tools.parser),
        packages.treesitter_ensure_installed
      )
      assert.same(derive_by_ft("formatter"), packages.formatters_by_ft)
      assert.same(derive_by_ft("linter"), packages.linters_by_ft)
    end
  )
end)
