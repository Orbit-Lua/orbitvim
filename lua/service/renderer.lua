local M = {}

local cfg = require("service.config")
local state_mod = require("service.state")
local highlights = require("utils.hl")
local str = require("utils.str")
local table_view = require("service.table")
local live_update = require("service.live_update")
local layout = require("service.layout")
local row_model = require("service.rows")
local help_view = require("service.help")
local cursor = require("service.cursor")

---@class Service.Renderer.State
---@field ui Service.UI?
---@field ns integer?

---@type Service.Renderer.State
local _state = { ui = nil, ns = nil }

---@param opts { ui: Service.UI, ns: integer }
function M.init(opts)
  _state.ui = opts.ui
  _state.ns = opts.ns
  live_update.init({ ui = opts.ui, render = M.render })
end

---@return vim.api.keyset.win_config
function M.make_win_cfg()
  return layout.make_win_cfg(_state.ui)
end

---@return nil
function M.render()
  if not (_state.ui.buf and vim.api.nvim_buf_is_valid(_state.ui.buf)) then
    return
  end
  _state.ui.help_open = false

  local category = cfg.service_categories[_state.ui.category_idx]
  local wcfg = M.make_win_cfg()
  local win_width = wcfg.width
  local sep = string.rep(
    cfg.layout.separator_char,
    win_width - cfg.layout.separator_inset
  )

  local tabline, tab_ranges, hint_byte, hint =
    layout.build_tabline(_state.ui, win_width)
  local columns, rows = row_model.build(_state.ui, category)

  local lines = {}
  local tabline_lnum, sep_lnum, scope_lnum, header_lnum

  layout.add_margin(lines, win_width)
  table.insert(lines, str.fill_line(tabline, win_width))
  tabline_lnum = #lines
  layout.add_margin(lines, win_width)
  table.insert(lines, str.fill_line(cfg.layout.line_prefix .. sep, win_width))
  sep_lnum = #lines
  layout.add_margin(lines, win_width)
  table.insert(
    lines,
    str.fill_line(layout.scope_line(_state.ui, category), win_width)
  )
  scope_lnum = #lines
  layout.add_margin(lines, win_width)

  _state.ui.line_map = {}

  if #rows == 0 then
    local message = _state.ui.scope == "buffer"
        and cfg.labels.no_current_services
      or cfg.labels.no_category_services
    table.insert(
      lines,
      table_view.empty_line(message, win_width, cfg.table.empty_prefix)
    )
  else
    local col_hdr, row_lines, row_map = table_view.render({
      columns = columns,
      rows = rows,
      width = win_width,
      indent = cfg.table.indent,
      separator = cfg.table.separator,
      cell_padding = cfg.table.cell_padding,
    })
    table.insert(lines, str.fill_line(col_hdr, win_width))
    header_lnum = #lines

    local base = #lines
    vim.list_extend(lines, row_lines)
    for lnum, entry in pairs(row_map) do
      _state.ui.line_map[base + lnum] = entry
    end
  end

  vim.bo[_state.ui.buf].modifiable = true
  vim.api.nvim_buf_set_lines(_state.ui.buf, 0, -1, false, lines)
  vim.bo[_state.ui.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(_state.ui.buf, _state.ns, 0, -1)

  for i, range in ipairs(tab_ranges) do
    local tab_highlight = (i == _state.ui.category_idx)
        and "DiagnosticVirtualTextInfo"
      or "TabLine"
    highlights.buf_hl(
      _state.ui.buf,
      _state.ns,
      tab_highlight,
      tabline_lnum - 1,
      range[1],
      range[2]
    )
  end
  highlights.buf_hl(
    _state.ui.buf,
    _state.ns,
    "Comment",
    tabline_lnum - 1,
    hint_byte,
    hint_byte + #hint
  )
  highlights.buf_hl(_state.ui.buf, _state.ns, "Comment", sep_lnum - 1, 0, -1)
  highlights.buf_hl(_state.ui.buf, _state.ns, "Comment", scope_lnum - 1, 0, -1)
  if header_lnum then
    highlights.buf_hl(
      _state.ui.buf,
      _state.ns,
      "Comment",
      header_lnum - 1,
      0,
      -1
    )
  end

  for lnum, entry in pairs(_state.ui.line_map) do
    local tree_hl = entry.kind == "detail" and "Comment" or "Title"
    local icon_hl = entry.kind == "ft_group" and "Title"
      or entry.kind == "detail" and "Comment"
      or entry.icon_hl
      or state_mod.is_enabled(category, entry.name) and "DiagnosticOk"
      or "Comment"
    if entry.tree_byte and entry.tree_end_byte then
      highlights.buf_hl(
        _state.ui.buf,
        _state.ns,
        tree_hl,
        lnum - 1,
        entry.tree_byte,
        entry.tree_end_byte
      )
    end
    highlights.buf_hl(
      _state.ui.buf,
      _state.ns,
      icon_hl,
      lnum - 1,
      entry.icon_byte,
      entry.icon_end_byte or entry.icon_byte
    )
    highlights.buf_hl(
      _state.ui.buf,
      _state.ns,
      entry.status_hl,
      lnum - 1,
      entry.status_byte,
      entry.status_end_byte or entry.status_byte
    )
  end

  if _state.ui.win and vim.api.nvim_win_is_valid(_state.ui.win) then
    vim.api.nvim_win_set_config(_state.ui.win, {
      relative = "editor",
      width = wcfg.width,
      height = wcfg.height,
      row = wcfg.row,
      col = wcfg.col,
    })

    cursor.clamp_to_entries(_state.ui)
  end
end

---@return nil
function M.render_help()
  if not (_state.ui.buf and vim.api.nvim_buf_is_valid(_state.ui.buf)) then
    return
  end
  _state.ui.line_map = {}

  local win_width = vim.api.nvim_win_get_width(_state.ui.win)
  local lines, section_lnums = help_view.build(win_width)

  vim.bo[_state.ui.buf].modifiable = true
  vim.api.nvim_buf_set_lines(_state.ui.buf, 0, -1, false, lines)
  vim.bo[_state.ui.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(_state.ui.buf, _state.ns, 0, -1)

  for lnum in pairs(section_lnums) do
    highlights.buf_hl(_state.ui.buf, _state.ns, "Title", lnum - 1, 0, -1)
  end
end

---@return nil
function M.toggle_help()
  _state.ui.help_open = not _state.ui.help_open
  if _state.ui.help_open then
    M.render_help()
  else
    M.render()
  end
end

---@return nil
function M.start_live_update()
  live_update.start()
end

---@return nil
function M.stop_live_update()
  live_update.stop()
end

return M
