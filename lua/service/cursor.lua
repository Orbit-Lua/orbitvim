local M = {}

---@param ui Service.UI
---@return Service.Entry?
function M.current_entry(ui)
  if not ui.win or ui.help_open then
    return nil
  end
  return ui.line_map[vim.api.nvim_win_get_cursor(ui.win)[1]]
end

---@param ui Service.UI
---@return integer?
function M.first_entry_lnum(ui)
  local first
  for lnum in pairs(ui.line_map or {}) do
    first = first and math.min(first, lnum) or lnum
  end
  return first
end

---@param ui Service.UI
---@return integer?
local function last_entry_lnum(ui)
  local last
  for lnum in pairs(ui.line_map or {}) do
    last = last and math.max(last, lnum) or lnum
  end
  return last
end

---@param ui Service.UI
---@return nil
function M.focus_first(ui)
  local first = M.first_entry_lnum(ui)
  if first and ui.win and vim.api.nvim_win_is_valid(ui.win) then
    vim.api.nvim_win_set_cursor(ui.win, { first, 0 })
  end
end

---@param ui Service.UI
---@param predicate fun(entry: Service.Entry): boolean
---@return boolean
function M.focus_match(ui, predicate)
  if not (ui.win and vim.api.nvim_win_is_valid(ui.win)) then
    return false
  end
  for lnum, entry in pairs(ui.line_map or {}) do
    if predicate(entry) then
      vim.api.nvim_win_set_cursor(ui.win, { lnum, 0 })
      return true
    end
  end
  return false
end

---@param ui Service.UI
---@return nil
function M.clamp_to_entries(ui)
  if not (ui.win and vim.api.nvim_win_is_valid(ui.win)) then
    return
  end

  local first = M.first_entry_lnum(ui)
  local last = last_entry_lnum(ui)
  if not first or not last then
    return
  end

  local cur = vim.api.nvim_win_get_cursor(ui.win)[1]
  if cur < first then
    vim.api.nvim_win_set_cursor(ui.win, { first, 0 })
  elseif cur > last then
    vim.api.nvim_win_set_cursor(ui.win, { last, 0 })
  end
end

return M
