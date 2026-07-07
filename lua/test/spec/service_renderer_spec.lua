describe("service.renderer", function()
  local renderer
  local ui
  local ns
  local buf
  local win

  before_each(function()
    package.loaded["service.renderer"] = nil
    renderer = require("service.renderer")
    ns = vim.api.nvim_create_namespace("ServiceRendererSpec")
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
    renderer.init({ ui = ui, ns = ns })
  end)

  after_each(function()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)

  it("renders service rows and line map into the buffer", function()
    renderer.render()

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.is_true(#lines > 0)
    assert.is_true(vim.tbl_count(ui.line_map) > 0)

    local first
    for lnum in pairs(ui.line_map) do
      first = first and math.min(first, lnum) or lnum
    end
    assert.equals("service", ui.line_map[first].kind)
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

    renderer.render_help()

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.same({}, ui.line_map)
    assert.is_true(lines[2]:find("? Help", 1, true) ~= nil)
  end)
end)
