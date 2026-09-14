describe("tool.data", function()
  local data = require("tool.data")
  local tools = require("config.tools")

  after_each(function()
    tools.formatter._test_default_a = nil
    tools.formatter._test_default_b = nil
    tools.formatter_defaults._test_default_order = nil
    package.loaded.conform = nil
  end)

  it("derives content height from flat and grouped categories", function()
    assert.equals(vim.tbl_count(tools.lsp), data.content_lines("lsp"))
    assert.equals(vim.tbl_count(tools.dap), data.content_lines("dap"))

    for _, category in ipairs({ "formatter", "linter" }) do
      local expected = 0
      for _, group in ipairs(data.build_ft_groups(category)) do
        expected = expected + 1 + #group.names
      end
      assert.equals(expected, data.content_lines(category), category)
    end
  end)

  it(
    "builds sorted, complete filetype groups for ordered categories",
    function()
      for _, category in ipairs({ "formatter", "linter" }) do
        local groups = data.build_ft_groups(category)
        local by_ft = {}
        local filetypes = {}

        for _, group in ipairs(groups) do
          assert.is_true(group.ft ~= "")
          assert.is_true(#group.names > 0)
          by_ft[group.ft] = group.names
          table.insert(filetypes, group.ft)
        end

        local sorted = vim.deepcopy(filetypes)
        table.sort(sorted)
        assert.same(sorted, filetypes, category .. " filetypes")

        for name, definition in pairs(tools[category]) do
          for _, ft in ipairs(definition.ft) do
            assert.is_true(
              vim.tbl_contains(by_ft[ft], name),
              category .. "." .. name .. " missing from " .. ft
            )
          end
        end
      end
    end
  )

  it("uses canonical defaults when no saved order exists", function()
    tools.formatter._test_default_a = {
      mason = nil,
      ft = { "_test_default_order" },
    }
    tools.formatter._test_default_b = {
      mason = nil,
      ft = { "_test_default_order" },
    }
    tools.formatter_defaults._test_default_order = {
      "_test_default_b",
      "_test_default_a",
    }

    local groups = data.build_ft_groups("formatter", "_test_default_order")

    assert.equals(1, #groups)
    assert.same({ "_test_default_b", "_test_default_a" }, groups[1].names)
  end)

  it("filters groups and entries by filetype", function()
    local groups = data.build_ft_groups("formatter", "python")
    assert.equals(1, #groups)
    assert.equals("python", groups[1].ft)

    local entries = data.tool_entries("lsp", "lua")
    assert.is_true(#entries > 0)
    for _, entry in ipairs(entries) do
      assert.is_true(vim.tbl_contains(entry.meta.ft, "lua"))
    end
    assert.same({}, data.tool_entries("lsp", ""))
  end)

  it("returns tool entries in deterministic name order", function()
    local entries = data.tool_entries("lsp")
    local names = vim.tbl_map(function(entry)
      return entry.name
    end, entries)
    local sorted = vim.deepcopy(names)
    table.sort(sorted)
    assert.same(sorted, names)
  end)

  it("summarizes enabled and disabled tools", function()
    local summary = data.state_summary("formatter")
    assert.equals(vim.tbl_count(tools.formatter), summary.total)
    assert.equals(summary.total, summary.enabled + summary.disabled)
  end)

  it("combines runtime health with external installation state", function()
    package.loaded.conform = {
      formatters_by_ft = { prisma = { "prisma_fmt" } },
    }

    local status, highlight =
      data.entry_status("formatter", "prisma_fmt", tools.formatter.prisma_fmt)

    assert.equals("configured · external", status)
    assert.equals("DiagnosticOk", highlight)
  end)
end)
