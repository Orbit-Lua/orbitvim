local M = {}

local cfg = require("tool.config")
local renderer = require("tool.ui.renderer")
local live_update = require("tool.ui.live_update")
local actions = require("tool.actions")
local cursor = require("tool.ui.cursor")

---@type Tool.UI
local ui = {
  buf = nil,
  win = nil,
  category_idx = 1,
  scope = "buffer",
  source_buf = nil,
  source_ft = nil,
  source_name = nil,
  help_open = false,
  line_map = {},
  live_augroup = nil,
  expanded = {},
}
local ns = vim.api.nvim_create_namespace("ToolManager")
local tooltip_ns = vim.api.nvim_create_namespace("ToolManagerTooltip")
---@class Tool.UIContext
---@field ui Tool.UI
---@field ns integer
---@field tooltip_ns integer
---@field tooltip_win integer?
---@field debounce_timer uv_timer_t?
---@field render fun()
local context = {
  ui = ui,
  ns = ns,
  tooltip_ns = tooltip_ns,
  tooltip_win = nil,
  debounce_timer = nil,
}
context.render = function()
  renderer.render(context)
end

---@return nil
local function set_keymaps()
  local keymap_opts = { buffer = ui.buf, nowait = true, silent = true }
  local function map(k, fn)
    vim.keymap.set("n", k, fn, keymap_opts)
  end

  map("q", M.close)
  map("<Esc>", M.close)
  map("?", function()
    renderer.toggle_help(context)
  end)
  map("g?", function()
    renderer.toggle_help(context)
  end)
  map("s", function()
    actions.toggle_scope(context)
  end)
  map("<Space>", function()
    actions.do_toggle(context)
  end)
  map("i", function()
    actions.do_install(context)
  end)
  map("<Tab>", function()
    actions.switch_tab(context, (ui.category_idx % #cfg.tool_categories) + 1)
  end)
  map("<S-Tab>", function()
    actions.switch_tab(
      context,
      ((ui.category_idx - 2) % #cfg.tool_categories) + 1
    )
  end)
  map("[", function()
    actions.do_reorder(context, -1)
  end)
  map("]", function()
    actions.do_reorder(context, 1)
  end)
  map("K", function()
    actions.show_tooltip_at_cursor(context)
  end)
  map("o", function()
    actions.toggle_expand(context)
  end)
  map("<CR>", function()
    actions.toggle_expand(context)
  end)
  map("za", function()
    actions.toggle_expand(context)
  end)

  for i = 1, #cfg.tool_categories do
    map(tostring(i), function()
      actions.switch_tab(context, i)
    end)
  end
end

---@return nil
function M.open()
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    vim.api.nvim_set_current_win(ui.win)
    return
  end

  ui.source_buf = vim.api.nvim_get_current_buf()
  ui.source_ft = vim.bo[ui.source_buf].filetype
  ui.source_name = vim.api.nvim_buf_get_name(ui.source_buf)
  ui.scope = "buffer"

  ui.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[ui.buf].filetype = "ToolManager"
  vim.bo[ui.buf].bufhidden = "wipe"

  ui.win = vim.api.nvim_open_win(ui.buf, true, renderer.make_win_cfg(context))
  vim.wo[ui.win].cursorline = true
  vim.wo[ui.win].wrap = false
  vim.wo[ui.win].number = false
  vim.wo[ui.win].relativenumber = false

  set_keymaps()
  live_update.start(context)

  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = ui.buf,
    once = true,
    callback = function()
      live_update.stop(context)
      ui.win = nil
      ui.buf = nil
    end,
  })

  renderer.render(context)
  cursor.focus_first(ui)
end

---@return nil
function M.close()
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    vim.api.nvim_win_close(ui.win, true)
  end
  ui.win = nil
  ui.buf = nil
end

return M
