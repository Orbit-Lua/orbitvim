local M = {}

local cfg = require("service.config")
local core = require("service.core")
local data = require("service.data")
local mason = require("service.mason")
local state_mod = require("service.state")
local borders = require("config.borders")
local ui_utils = require("utils.ui")
local logger = require("utils.logger")
local category_handlers = require("service.category")

---@class Service.Actions.State
---@field ui Service.UI?
---@field tooltip_ns integer?
---@field render (fun())?
---@field tooltip_win integer?

---@type Service.Actions.State
local _state = { ui = nil, tooltip_ns = nil, render = nil, tooltip_win = nil }

---@param opts { ui: Service.UI, tooltip_ns: integer, render: fun() }
function M.init(opts)
  _state.ui = opts.ui
  _state.tooltip_ns = opts.tooltip_ns
  _state.render = opts.render
end

---@return Service.Entry?
local function current_entry()
  if not _state.ui.win or _state.ui.help_open then
    return nil
  end
  return _state.ui.line_map[vim.api.nvim_win_get_cursor(_state.ui.win)[1]]
end

---@return nil
function M.show_tooltip_at_cursor()
  if _state.tooltip_win and vim.api.nvim_win_is_valid(_state.tooltip_win) then
    if vim.api.nvim_get_current_win() == _state.tooltip_win then
      return
    end
    vim.api.nvim_set_current_win(_state.tooltip_win)
    return
  end

  local entry = current_entry()
  if not entry or not entry.meta then
    return
  end
  local category = cfg.service_categories[_state.ui.category_idx]

  local install_status = ""
  if entry.meta.mason then
    local installed = mason.package_status(entry.meta.mason)
    install_status = installed and " ✓" or " ✗"
  end

  local is_entry_enabled = state_mod.is_enabled(category, entry.name)
  local icon = is_entry_enabled and "●" or "○"
  local ft_str = table.concat(entry.meta.ft or {}, ", ")
  local status_text, status_hl =
    data.entry_status(category, entry.name, entry.meta)

  local tooltip_lines = {}
  table.insert(tooltip_lines, " " .. icon .. "  " .. entry.name .. " ")
  if ft_str ~= "" then
    table.insert(tooltip_lines, "   ft:     " .. ft_str .. " ")
  end
  if entry.meta.mason then
    table.insert(
      tooltip_lines,
      "   mason:  " .. entry.meta.mason .. install_status .. " "
    )
  end
  table.insert(tooltip_lines, "   status: " .. status_text .. " ")
  if entry.meta.note and entry.meta.note ~= "" then
    table.insert(tooltip_lines, "   note:   " .. entry.meta.note .. " ")
  end

  if category == "linter" and is_entry_enabled then
    local run_errors = logger.get_entries("linter", entry.name)
    if #run_errors > 0 then
      table.insert(
        tooltip_lines,
        "   ──────────────────────────── "
      )
      for _, run_error in ipairs(run_errors) do
        local level_char = run_error.level == "ERROR" and "E" or "W"
        local text = string.format("   %s  %s ", level_char, run_error.message)
        if vim.fn.strdisplaywidth(text) > cfg.tooltip.max_w then
          text = text:sub(1, cfg.tooltip.max_w - 1) .. "… "
        end
        table.insert(tooltip_lines, text)
      end
    end

    local diagnostic_summary =
      category_handlers.linter.get_linter_diagnostics(entry.name)
    if #diagnostic_summary.messages > 0 then
      table.insert(
        tooltip_lines,
        "   ──────────────────────────── "
      )
      local overflow = #diagnostic_summary.messages - cfg.tooltip.max_messages
      for j, msg in ipairs(diagnostic_summary.messages) do
        if j > cfg.tooltip.max_messages then
          table.insert(tooltip_lines, "   +" .. overflow .. " more ")
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
        if vim.fn.strdisplaywidth(text) > cfg.tooltip.max_w then
          text = text:sub(1, cfg.tooltip.max_w - 1) .. "… "
        end
        table.insert(tooltip_lines, text)
      end
    end
  end

  local max_w = 0
  for _, line in ipairs(tooltip_lines) do
    max_w = math.max(max_w, vim.fn.strdisplaywidth(line))
  end

  local tooltip_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(tooltip_buf, 0, -1, false, tooltip_lines)

  local name_hl = is_entry_enabled and "DiagnosticOk" or "Comment"
  ui_utils.buf_hl(tooltip_buf, _state.tooltip_ns, name_hl, 0, 1, 4)

  for i, line in ipairs(tooltip_lines) do
    if line:match("^   status:") then
      local prefix_len = #"   status: "
      ui_utils.buf_hl(
        tooltip_buf,
        _state.tooltip_ns,
        status_hl,
        i - 1,
        prefix_len,
        -1
      )
    elseif line:match("^   E  ") then
      ui_utils.buf_hl(
        tooltip_buf,
        _state.tooltip_ns,
        "DiagnosticError",
        i - 1,
        3,
        4
      )
    elseif line:match("^   W  ") then
      ui_utils.buf_hl(
        tooltip_buf,
        _state.tooltip_ns,
        "DiagnosticWarn",
        i - 1,
        3,
        4
      )
    end
  end

  local cursor = vim.api.nvim_win_get_cursor(_state.ui.win)
  local screen_pos = vim.fn.screenpos(_state.ui.win, cursor[1], cursor[2] + 1)
  local screen_col = screen_pos.col

  local float_w = max_w + 2

  -- Mirror vim.lsp.util.make_floating_popup_options: compare lines above vs
  -- below and use SW anchor to avoid manual height arithmetic.
  local lines_above = cursor[1] - 1
  local lines_below = vim.o.lines - cursor[1] - vim.o.cmdheight
  local anchor, float_row
  if lines_above > lines_below then
    anchor = "SW"
    float_row = 0
  else
    anchor = "NW"
    float_row = 1
  end

  -- Prefer right; fall back to left when right lacks space but left has it.
  local right_space = vim.o.columns - screen_col
  local left_space = screen_col - 1
  local is_right = right_space >= float_w or left_space < float_w
  local float_col = (is_right and 1 or -float_w)

  -- Declared before close() so the function captures them as upvalues.
  local cursor_autocmd_id
  local win_closed_autocmd_id
  local tooltip_win

  local function close()
    if tooltip_win and vim.api.nvim_win_is_valid(tooltip_win) then
      vim.api.nvim_win_close(tooltip_win, true)
    end
    if _state.tooltip_win == tooltip_win then
      _state.tooltip_win = nil
    end
    pcall(vim.api.nvim_del_autocmd, cursor_autocmd_id)
    pcall(vim.api.nvim_del_autocmd, win_closed_autocmd_id)
  end

  tooltip_win = vim.api.nvim_open_win(tooltip_buf, false, {
    relative = "cursor",
    anchor = anchor,
    row = float_row,
    col = float_col,
    width = max_w,
    height = #tooltip_lines,
    style = "minimal",
    border = borders.default,
    focusable = true,
    zindex = 100,
    noautocmd = true,
  })
  _state.tooltip_win = tooltip_win

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      close()
      if _state.ui.win and vim.api.nvim_win_is_valid(_state.ui.win) then
        vim.api.nvim_set_current_win(_state.ui.win)
      end
    end, { buffer = tooltip_buf, nowait = true, silent = true })
  end
  vim.keymap.set(
    "n",
    "K",
    "<nop>",
    { buffer = tooltip_buf, nowait = true, silent = true }
  )

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

---@return nil
function M.do_toggle()
  local entry = current_entry()
  if not entry or not entry.meta then
    return
  end
  local category = cfg.service_categories[_state.ui.category_idx]
  local is_now_enabled = not state_mod.is_enabled(category, entry.name)

  if is_now_enabled and entry.meta.mason then
    local pkg, err = mason.get_package(entry.meta.mason)
    if pkg and not pkg:is_installed() then
      if cfg.missing_package_policy == "manual" then
        vim.notify(
          entry.meta.mason .. " is not installed; press i to install",
          vim.log.levels.WARN
        )
        return
      end

      if cfg.missing_package_policy == "auto" then
        mason.install(entry.meta.mason, function()
          state_mod.set_enabled(category, entry.name, true)
          category_handlers[category].apply_runtime({
            name = entry.name,
            meta = entry.meta,
            is_enabled = true,
          })
          _state.render()
        end)
        return
      end
    elseif not pkg then
      vim.notify("ServiceManager: " .. err, vim.log.levels.WARN)
    end
  end

  state_mod.set_enabled(category, entry.name, is_now_enabled)
  category_handlers[category].apply_runtime({
    name = entry.name,
    meta = entry.meta,
    is_enabled = is_now_enabled,
  })
  _state.render()
end

---@return nil
function M.do_install()
  local entry = current_entry()
  if not entry or not entry.meta then
    return
  end
  if not entry.meta.mason then
    vim.notify(
      "No mason package for "
        .. entry.name
        .. (entry.meta.note and (" — " .. entry.meta.note) or ""),
      vim.log.levels.WARN
    )
    return
  end
  mason.install(entry.meta.mason, _state.render)
end

---@param dir integer -1 for up, 1 for down
---@return nil
function M.do_reorder(dir)
  local entry = current_entry()
  if not entry or not entry.ft or not entry.order_names then
    return
  end
  local category = cfg.service_categories[_state.ui.category_idx]

  local names = vim.deepcopy(entry.order_names)
  local current_idx
  for i, n in ipairs(names) do
    if n == entry.name then
      current_idx = i
      break
    end
  end
  if not current_idx then
    return
  end

  local new_idx = current_idx + dir
  if new_idx < 1 or new_idx > #names then
    return
  end

  names[current_idx], names[new_idx] = names[new_idx], names[current_idx]

  if category == "linter" or category == "formatter" then
    state_mod.set_order(
      category --[[@as "formatter"|"linter"]],
      entry.ft,
      names
    )
  end

  local enabled_names = vim.tbl_filter(function(n)
    return state_mod.is_enabled(category, n)
  end, names)
  local handler = category_handlers[category]
  if handler and handler.apply_order then
    handler.apply_order({ ft = entry.ft, enabled_names = enabled_names })
  end

  _state.render()

  for lnum, e in pairs(_state.ui.line_map) do
    if e.name == entry.name and e.ft == entry.ft then
      vim.api.nvim_win_set_cursor(_state.ui.win, { lnum, 0 })
      break
    end
  end
end

---@return nil
function M.toggle_expand()
  if _state.ui.help_open then
    return
  end
  local entry = current_entry()
  if not entry then
    return
  end
  local category = cfg.service_categories[_state.ui.category_idx]

  local key
  if core.is_ordered_category(category) and entry.ft then
    key = core.ft_key(category, entry.ft)
    local is_expanded = _state.ui.expanded[key]
    if is_expanded == nil then
      is_expanded = _state.ui.scope == "buffer"
    end
    _state.ui.expanded[key] = not is_expanded
  elseif entry.name then
    key = core.service_key(category, entry.name)
    _state.ui.expanded[key] = not _state.ui.expanded[key]
  else
    return
  end

  _state.render()
end

---@param idx integer
---@return nil
function M.switch_tab(idx)
  _state.ui.category_idx = idx
  _state.render()
  local first
  for lnum in pairs(_state.ui.line_map) do
    first = first and math.min(first, lnum) or lnum
  end
  if first and _state.ui.win and vim.api.nvim_win_is_valid(_state.ui.win) then
    vim.api.nvim_win_set_cursor(_state.ui.win, { first, 0 })
  end
end

---@return nil
function M.toggle_scope()
  _state.ui.scope = _state.ui.scope == "buffer" and "states" or "buffer"
  _state.render()
  local first
  for lnum in pairs(_state.ui.line_map) do
    first = first and math.min(first, lnum) or lnum
  end
  if first and _state.ui.win and vim.api.nvim_win_is_valid(_state.ui.win) then
    vim.api.nvim_win_set_cursor(_state.ui.win, { first, 0 })
  end
end

return M
