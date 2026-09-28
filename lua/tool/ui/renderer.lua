local M = {}

local cfg = require("tool.config")
local state_mod = require("tool.state")
local highlights = require("utils.hl")
local str = require("utils.str")
local table_view = require("tool.ui.table")
local layout = require("tool.ui.layout")
local row_model = require("tool.ui.rows")
local help_view = require("tool.ui.help")
local cursor = require("tool.ui.cursor")

---@return vim.api.keyset.win_config
function M.make_win_cfg(ctx)
  local category = cfg.tool_categories[ctx.ui.category_idx]
  local _, rows = row_model.build(ctx.ui, category)
  return layout.make_win_cfg(#rows)
end

---@return nil
function M.render(ctx)
  if not (ctx.ui.buf and vim.api.nvim_buf_is_valid(ctx.ui.buf)) then
    return
  end
  ctx.ui.help_open = false

  local category = cfg.tool_categories[ctx.ui.category_idx]
  local columns, rows = row_model.build(ctx.ui, category)
  local wcfg = layout.make_win_cfg(#rows)
  local win_width = wcfg.width
  local sep = string.rep(
    cfg.layout.separator_char,
    win_width - cfg.layout.separator_inset
  )

  local tabline, tab_ranges, hint_byte, hint =
    layout.build_tabline(ctx.ui, win_width)
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
    str.fill_line(layout.scope_line(ctx.ui, category), win_width)
  )
  scope_lnum = #lines
  layout.add_margin(lines, win_width)

  ctx.ui.line_map = {}

  if #rows == 0 then
    local message = ctx.ui.scope == "buffer" and cfg.labels.no_current_tools
      or cfg.labels.no_category_tools
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
      ctx.ui.line_map[base + lnum] = entry
    end
  end

  vim.bo[ctx.ui.buf].modifiable = true
  vim.api.nvim_buf_set_lines(ctx.ui.buf, 0, -1, false, lines)
  vim.bo[ctx.ui.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(ctx.ui.buf, ctx.ns, 0, -1)

  for i, range in ipairs(tab_ranges) do
    local tab_highlight = (i == ctx.ui.category_idx)
        and "DiagnosticVirtualTextInfo"
      or "TabLine"
    highlights.buf_hl(
      ctx.ui.buf,
      ctx.ns,
      tab_highlight,
      tabline_lnum - 1,
      range[1],
      range[2]
    )
  end
  highlights.buf_hl(
    ctx.ui.buf,
    ctx.ns,
    "Comment",
    tabline_lnum - 1,
    hint_byte,
    hint_byte + #hint
  )
  highlights.buf_hl(ctx.ui.buf, ctx.ns, "Comment", sep_lnum - 1, 0, -1)
  highlights.buf_hl(ctx.ui.buf, ctx.ns, "Comment", scope_lnum - 1, 0, -1)
  if header_lnum then
    highlights.buf_hl(ctx.ui.buf, ctx.ns, "Comment", header_lnum - 1, 0, -1)
  end

  for lnum, entry in pairs(ctx.ui.line_map) do
    local tree_hl = entry.kind == "detail" and "Comment" or "Title"
    local icon_hl = entry.kind == "ft_group" and "Title"
      or entry.kind == "detail" and "Comment"
      or entry.icon_hl
      or state_mod.is_enabled(category, entry.name) and "DiagnosticOk"
      or "Comment"
    if entry.tree_byte and entry.tree_end_byte then
      highlights.buf_hl(
        ctx.ui.buf,
        ctx.ns,
        tree_hl,
        lnum - 1,
        entry.tree_byte,
        entry.tree_end_byte
      )
    end
    highlights.buf_hl(
      ctx.ui.buf,
      ctx.ns,
      icon_hl,
      lnum - 1,
      entry.icon_byte,
      entry.icon_end_byte or entry.icon_byte
    )
    highlights.buf_hl(
      ctx.ui.buf,
      ctx.ns,
      entry.status_hl,
      lnum - 1,
      entry.status_byte,
      entry.status_end_byte or entry.status_byte
    )
  end

  if ctx.ui.win and vim.api.nvim_win_is_valid(ctx.ui.win) then
    vim.api.nvim_win_set_config(ctx.ui.win, {
      relative = "editor",
      width = wcfg.width,
      height = wcfg.height,
      row = wcfg.row,
      col = wcfg.col,
    })

    cursor.clamp_to_entries(ctx.ui)
  end
end

---@return nil
function M.render_help(ctx)
  if not (ctx.ui.buf and vim.api.nvim_buf_is_valid(ctx.ui.buf)) then
    return
  end
  ctx.ui.line_map = {}

  local win_width = vim.api.nvim_win_get_width(ctx.ui.win)
  local lines, section_lnums = help_view.build(win_width)

  vim.bo[ctx.ui.buf].modifiable = true
  vim.api.nvim_buf_set_lines(ctx.ui.buf, 0, -1, false, lines)
  vim.bo[ctx.ui.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(ctx.ui.buf, ctx.ns, 0, -1)

  for lnum in pairs(section_lnums) do
    highlights.buf_hl(ctx.ui.buf, ctx.ns, "Title", lnum - 1, 0, -1)
  end
end

---@return nil
function M.toggle_help(ctx)
  ctx.ui.help_open = not ctx.ui.help_open
  if ctx.ui.help_open then
    M.render_help(ctx)
  else
    M.render(ctx)
  end
end

---@return nil
return M
