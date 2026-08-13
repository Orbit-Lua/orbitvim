describe("config.packages", function()
  local packages = require("config.packages")
  local tools = require("config.tools")

  local function sorted_keys(tbl)
    local result = vim.tbl_keys(tbl)
    table.sort(result)
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

  it("derives the sorted parser list from the tool registry", function()
    assert.same(sorted_keys(tools.parser), packages.treesitter_ensure_installed)
  end)
end)
