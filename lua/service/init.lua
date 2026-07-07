local M = {}

local cfg = require("service.config")
local renderer = require("service.renderer")
local actions = require("service.actions")
local cursor = require("service.cursor")

---@type Service.UI
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
local ns = vim.api.nvim_create_namespace("ServiceManager")
local tooltip_ns = vim.api.nvim_create_namespace("ServiceManagerTooltip")

renderer.init({ ui = ui, ns = ns })
actions.init({ ui = ui, tooltip_ns = tooltip_ns, render = renderer.render })

---@return nil
local function set_keymaps()
  local keymap_opts = { buffer = ui.buf, nowait = true, silent = true }
  local function map(k, fn)
    vim.keymap.set("n", k, fn, keymap_opts)
  end

  map("q", M.close)
  map("<Esc>", M.close)
  map("?", renderer.toggle_help)
  map("g?", renderer.toggle_help)
  map("s", actions.toggle_scope)
  map("<Space>", actions.do_toggle)
  map("i", actions.do_install)
  map("<Tab>", function()
    actions.switch_tab((ui.category_idx % #cfg.service_categories) + 1)
  end)
  map("<S-Tab>", function()
    actions.switch_tab(((ui.category_idx - 2) % #cfg.service_categories) + 1)
  end)
  map("[", function()
    actions.do_reorder(-1)
  end)
  map("]", function()
    actions.do_reorder(1)
  end)
  map("K", actions.show_tooltip_at_cursor)
  map("o", actions.toggle_expand)
  map("<CR>", actions.toggle_expand)
  map("za", actions.toggle_expand)

  for i = 1, #cfg.service_categories do
    map(tostring(i), function()
      actions.switch_tab(i)
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
  vim.bo[ui.buf].filetype = "ServiceManager"
  vim.bo[ui.buf].bufhidden = "wipe"

  ui.win = vim.api.nvim_open_win(ui.buf, true, renderer.make_win_cfg())
  vim.wo[ui.win].cursorline = true
  vim.wo[ui.win].wrap = false
  vim.wo[ui.win].number = false
  vim.wo[ui.win].relativenumber = false

  set_keymaps()
  renderer.start_live_update()

  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = ui.buf,
    once = true,
    callback = function()
      renderer.stop_live_update()
      ui.win = nil
      ui.buf = nil
    end,
  })

  renderer.render()
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
