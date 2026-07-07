describe("service.rows", function()
  local rows = require("service.rows")

  local function ui(overrides)
    return vim.tbl_extend("force", {
      category_idx = 1,
      scope = "buffer",
      source_ft = "lua",
      source_name = "init.lua",
      expanded = {},
      line_map = {},
    }, overrides or {})
  end

  it("builds flat service rows for lsp categories", function()
    local columns, row_items = rows.build(ui(), "lsp")

    assert.equals("Service", columns[3].label)
    assert.is_true(#row_items > 0)
    for _, row in ipairs(row_items) do
      assert.equals("service", row.entry.kind)
      assert.is_not_nil(row.cells.name)
      assert.is_not_nil(row.cells.status)
    end
  end)

  it("builds grouped rows for ordered categories", function()
    local _, row_items = rows.build(ui({ source_ft = "python" }), "formatter")
    local has_group = false
    local has_service = false

    for _, row in ipairs(row_items) do
      if row.entry.kind == "ft_group" then
        has_group = true
        assert.equals("python", row.entry.ft)
      elseif row.entry.kind == "service" then
        has_service = true
        assert.equals("python", row.entry.ft)
        assert.is_true(type(row.entry.order_names) == "table")
      end
    end

    assert.is_true(has_group)
    assert.is_true(has_service)
  end)

  it("adds detail rows for expanded flat services", function()
    local _, row_items = rows.build(
      ui({ source_ft = "lua", expanded = { ["lsp:lua_ls"] = true } }),
      "lsp"
    )

    local has_detail = false
    for _, row in ipairs(row_items) do
      if row.entry.kind == "detail" then
        has_detail = true
        assert.equals("lua", row.entry.ft)
      end
    end
    assert.is_true(has_detail)
  end)
end)
