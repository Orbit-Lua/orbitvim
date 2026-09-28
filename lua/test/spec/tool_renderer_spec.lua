describe("tool.ui.renderer", function()
  local renderer
  local ui
  local ns
  local buf
  local win
  local context
  local old_editor_lines
  local old_min_h
  local old_max_h

  before_each(function()
    package.loaded["tool.ui.renderer"] = nil
    renderer = require("tool.ui.renderer")
    ns = vim.api.nvim_create_namespace("ToolRendererSpec")
    buf = vim.api.nvim_create_buf(false, true)
    ui = {
      buf = buf,
      win = nil,
      category_idx = 1,
      scope = "buffer",
      source_buf = nil,
      source_ft = "lua",
      source_name = "init.lua",
      help_open = false,
      line_map = {},
      live_augroup = nil,
      expanded = {},
    }
    context = { ui = ui, ns = ns }
    context.render = function()
      renderer.render(context)
    end
  end)

  after_each(function()
    if old_editor_lines then
      vim.o.lines = old_editor_lines
      old_editor_lines = nil
    end
    if old_min_h then
      local cfg = require("tool.config")
      cfg.min_h, cfg.max_h = old_min_h, old_max_h
      old_min_h, old_max_h = nil, nil
    end
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)

  it("renders tool rows and line map into the buffer", function()
    renderer.render(context)

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.is_true(#lines > 0)
    assert.is_true(vim.tbl_count(ui.line_map) > 0)

    local first
    for lnum in pairs(ui.line_map) do
      first = first and math.min(first, lnum) or lnum
    end
    assert.equals("tool", ui.line_map[first].kind)
  end)

  it("keeps expanded visible rows and window height aligned", function()
    old_editor_lines = vim.o.lines
    vim.o.lines = 100

    local cfg = require("tool.config")
    old_min_h, old_max_h = cfg.min_h, cfg.max_h
    cfg.min_h, cfg.max_h = 1, 95
    local core = require("tool.core")
    local row_model = require("tool.ui.rows")
    ui.scope = "states"
    ui.source_ft = nil

    local selected_category, selected_name, original_count
    for index, category in ipairs(cfg.tool_categories) do
      local _, rows = row_model.build(ui, category)
      for _, row in ipairs(rows) do
        if row.entry and row.entry.meta and #(row.entry.meta.ft or {}) > 0 then
          selected_category = category
          selected_name = row.entry.name
          original_count = #rows
          ui.category_idx = index
          break
        end
      end
      if selected_category then
        break
      end
    end

    assert.is_truthy(selected_category)
    ui.expanded[core.tool_key(selected_category, selected_name)] = true
    local _, expanded_rows = row_model.build(ui, selected_category)
    assert.is_true(#expanded_rows > original_count)

    win = vim.api.nvim_open_win(buf, false, renderer.make_win_cfg(context))
    ui.win = win
    renderer.render(context)

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.equals(#lines, vim.api.nvim_win_get_height(win))
    assert.equals(#expanded_rows, vim.tbl_count(ui.line_map))
  end)

  it("renders help through the extracted help view", function()
    win = vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      width = 80,
      height = 20,
      row = 0,
      col = 0,
      style = "minimal",
    })
    ui.win = win

    renderer.render_help(context)

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.same({}, ui.line_map)
    assert.is_true(lines[2]:find("? Help", 1, true) ~= nil)
  end)
end)
