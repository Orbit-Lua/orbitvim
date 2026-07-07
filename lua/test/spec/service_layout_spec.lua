describe("service.layout", function()
  local layout = require("service.layout")

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

  it("returns the active filetype only in buffer scope", function()
    assert.equals("lua", layout.active_ft(ui()))
    assert.is_nil(layout.active_ft(ui({ scope = "states" })))
  end)

  it("defaults ordered filetype expansion from scope", function()
    assert.is_true(layout.is_ft_expanded(ui(), "formatter", "lua"))
    assert.is_false(
      layout.is_ft_expanded(
        ui({ scope = "states", source_ft = nil }),
        "formatter",
        "lua"
      )
    )
  end)

  it("honors explicit filetype expansion state", function()
    local state = ui({ expanded = { ["formatter:ft:lua"] = false } })
    assert.is_false(layout.is_ft_expanded(state, "formatter", "lua"))
  end)

  it("builds tabline ranges and scope lines", function()
    local state = ui()
    local tabline, ranges, hint_byte, hint = layout.build_tabline(state, 120)

    assert.is_true(tabline:find("LSP", 1, true) ~= nil)
    assert.equals(4, #ranges)
    assert.is_true(hint_byte > ranges[#ranges][2])
    assert.equals("s states · ? help", hint)
    assert.is_true(
      layout.scope_line(state, "lsp"):find("ft=lua", 1, true) ~= nil
    )
  end)
end)
