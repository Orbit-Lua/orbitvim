local M = {}

local cfg = require("service.config")
local data = require("service.data")
local mason = require("service.mason")
local state_mod = require("service.state")
local borders = require("config.borders")
local highlights = require("utils.hl")
local logger = require("utils.logger")
local str = require("utils.str")
local category_handlers = require("service.category")
local cursor = require("service.cursor")

---@class Service.Tooltip.State
---@field ui Service.UI?
---@field ns integer?
---@field win integer?

---@type Service.Tooltip.State
local _state = { ui = nil, ns = nil, win = nil }

---@param opts { ui: Service.UI, ns: integer }
function M.init(opts)
  _state.ui = opts.ui
  _state.ns = opts.ns
end

---@return Service.Entry?
local function current_entry()
  return cursor.current_entry(_state.ui)
end

---@param line string
---@return string
local function truncate_line(line)
  if vim.fn.strdisplaywidth(line) <= cfg.tooltip.max_w then
    return line
  end
  return str.trunc(line, cfg.tooltip.max_w)
end

---@param lines string[]
local function append_separator(lines)
  table.insert(lines, "   " .. cfg.tooltip.separator_line .. " ")
end

---@class Service.Tooltip.BuildOpts
---@field category ServiceCategory
---@field entry Service.Entry
---@field is_enabled boolean?
---@field installed boolean?
---@field status_text string?
---@field status_hl string?
---@field run_errors table[]?
---@field diagnostic_summary Service.LinterDiagnosticSummary?

---@param opts Service.Tooltip.BuildOpts
---@return string[] lines
---@return string status_hl
---@return string name_hl
function M.build_lines(opts)
  local entry = opts.entry
  local category = opts.category
  local meta = entry.meta
  local is_enabled = opts.is_enabled
  if is_enabled == nil then
    is_enabled = state_mod.is_enabled(category, entry.name)
  end

  local status_text, status_hl = opts.status_text, opts.status_hl
  if not status_text or not status_hl then
    status_text, status_hl = data.entry_status(category, entry.name, meta)
  end

  local install_status = ""
  if meta.mason then
    local installed = opts.installed
    if installed == nil then
      installed = mason.package_status(meta.mason)
    end
    install_status = installed and (" " .. cfg.tooltip.installed_icon)
      or (" " .. cfg.tooltip.missing_icon)
  end

  local enabled_icon = is_enabled and cfg.tooltip.enabled_icon
    or cfg.tooltip.disabled_icon
  local ft_str = table.concat(meta.ft or {}, ", ")

  local lines = {}
  table.insert(lines, " " .. enabled_icon .. "  " .. entry.name .. " ")
  if ft_str ~= "" then
    table.insert(lines, "   ft:     " .. ft_str .. " ")
  end
  if meta.mason then
    table.insert(lines, "   mason:  " .. meta.mason .. install_status .. " ")
  end
  table.insert(lines, "   status: " .. status_text .. " ")
  if meta.note and meta.note ~= "" then
    table.insert(lines, "   note:   " .. meta.note .. " ")
  end

  if category == "linter" and is_enabled then
    local run_errors = opts.run_errors
      or logger.get_entries("linter", entry.name)
    if #run_errors > 0 then
      append_separator(lines)
      for _, run_error in ipairs(run_errors) do
        local level_char = run_error.level == "ERROR" and "E" or "W"
        local text = string.format("   %s  %s ", level_char, run_error.message)
        table.insert(lines, truncate_line(text))
      end
    end

    local diagnostic_summary = opts.diagnostic_summary
      or category_handlers.linter.get_linter_diagnostics(entry.name)
    if #diagnostic_summary.messages > 0 then
      append_separator(lines)
      local overflow = #diagnostic_summary.messages - cfg.tooltip.max_messages
      for j, msg in ipairs(diagnostic_summary.messages) do
        if j > cfg.tooltip.max_messages then
          table.insert(lines, "   +" .. overflow .. " more ")
          break
        end
        local sev_char = msg.severity == vim.diagnostic.severity.ERROR and "E"
          or "W"
        local text = string.format(
          "   %s  %s:%d  %s ",
          sev_char,
          msg.file,
          msg.lnum,
          msg.message
        )
        table.insert(lines, truncate_line(text))
      end
    end
  end

  local name_hl = is_enabled and "DiagnosticOk" or "Comment"
  return lines, status_hl, name_hl
end

---@param lines string[]
---@return integer
local function max_display_width(lines)
  local max_w = 0
  for _, line in ipairs(lines) do
    max_w = math.max(max_w, vim.fn.strdisplaywidth(line))
  end
  return max_w
end

---@param tooltip_buf integer
---@param lines string[]
---@param status_hl string
---@param name_hl string
local function apply_highlights(tooltip_buf, lines, status_hl, name_hl)
  highlights.buf_hl(tooltip_buf, _state.ns, name_hl, 0, 1, 4)

  for i, line in ipairs(lines) do
    if line:match("^   status:") then
      local prefix_len = #"   status: "
      highlights.buf_hl(
        tooltip_buf,
        _state.ns,
        status_hl,
        i - 1,
        prefix_len,
        -1
      )
    elseif line:match("^   E  ") then
      highlights.buf_hl(tooltip_buf, _state.ns, "DiagnosticError", i - 1, 3, 4)
    elseif line:match("^   W  ") then
      highlights.buf_hl(tooltip_buf, _state.ns, "DiagnosticWarn", i - 1, 3, 4)
    end
  end
end

---@param tooltip_win integer?
---@param cursor_autocmd_id integer?
---@param win_closed_autocmd_id integer?
local function close_window(
  tooltip_win,
  cursor_autocmd_id,
  win_closed_autocmd_id
)
  if tooltip_win and vim.api.nvim_win_is_valid(tooltip_win) then
    vim.api.nvim_win_close(tooltip_win, true)
  end
  if _state.win == tooltip_win then
    _state.win = nil
  end
  pcall(vim.api.nvim_del_autocmd, cursor_autocmd_id)
  pcall(vim.api.nvim_del_autocmd, win_closed_autocmd_id)
end

---@return nil
function M.close()
  close_window(_state.win, nil, nil)
end

---@return nil
function M.show_at_cursor()
  if _state.win and vim.api.nvim_win_is_valid(_state.win) then
    if vim.api.nvim_get_current_win() == _state.win then
      return
    end
    vim.api.nvim_set_current_win(_state.win)
    return
  end

  local entry = current_entry()
  if not entry or not entry.meta then
    return
  end
  local category = cfg.service_categories[_state.ui.category_idx]
  local lines, status_hl, name_hl = M.build_lines({
    category = category,
    entry = entry,
  })
  local max_w = max_display_width(lines)

  local tooltip_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(tooltip_buf, 0, -1, false, lines)
  apply_highlights(tooltip_buf, lines, status_hl, name_hl)

  local cursor_pos = vim.api.nvim_win_get_cursor(_state.ui.win)
  local screen_pos =
    vim.fn.screenpos(_state.ui.win, cursor_pos[1], cursor_pos[2] + 1)
  local screen_col = screen_pos.col
  local float_w = max_w + 2

  local lines_above = cursor_pos[1] - 1
  local lines_below = vim.o.lines - cursor_pos[1] - vim.o.cmdheight
  local anchor, float_row
  if lines_above > lines_below then
    anchor = "SW"
    float_row = 0
  else
    anchor = "NW"
    float_row = 1
  end

  local right_space = vim.o.columns - screen_col
  local left_space = screen_col - 1
  local is_right = right_space >= float_w or left_space < float_w
  local float_col = (is_right and 1 or -float_w)

  local cursor_autocmd_id
  local win_closed_autocmd_id
  local tooltip_win

  local function close()
    close_window(tooltip_win, cursor_autocmd_id, win_closed_autocmd_id)
  end

  tooltip_win = vim.api.nvim_open_win(tooltip_buf, false, {
    relative = "cursor",
    anchor = anchor,
    row = float_row,
    col = float_col,
    width = max_w,
    height = #lines,
    style = "minimal",
    border = borders.default,
    focusable = true,
    zindex = cfg.tooltip.zindex,
    noautocmd = true,
  })
  _state.win = tooltip_win

  for _, key in ipairs(cfg.tooltip.close_keys) do
    vim.keymap.set("n", key, function()
      close()
      if _state.ui.win and vim.api.nvim_win_is_valid(_state.ui.win) then
        vim.api.nvim_set_current_win(_state.ui.win)
      end
    end, { buffer = tooltip_buf, nowait = true, silent = true })
  end

  for _, key in ipairs(cfg.tooltip.disabled_keys) do
    vim.keymap.set(
      "n",
      key,
      "<nop>",
      { buffer = tooltip_buf, nowait = true, silent = true }
    )
  end

  win_closed_autocmd_id = vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(_state.ui.win),
    once = true,
    callback = close,
  })

  cursor_autocmd_id = vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = vim.api.nvim_win_get_buf(_state.ui.win),
    once = true,
    callback = close,
  })
end

return M
