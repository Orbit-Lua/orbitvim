local M = {}

local CONFIG = {
  completion = { max_w = 60, max_h = 15, pct_w = 0.4, pct_h = 0.3 },
  doc = { max_w = 80, max_h = 20, pct_w = 0.5, pct_h = 0.4 },
}

---@param win_id integer
---@return integer
M.get_text_offset = function(win_id)
  return vim.fn.getwininfo(win_id)[1].textoff
end

---@param winid? integer
---@return boolean
M.is_floating = function(winid)
  winid = winid or 0
  local cfg = vim.api.nvim_win_get_config(winid)
  return cfg.relative ~= ""
end

---@return integer?
M.get_editor_win = function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      return win
    end
  end
end

---@return integer, integer
M.get_completion_size = function()
  local max_width = math.min(
    CONFIG.completion.max_w,
    math.floor(vim.o.columns * CONFIG.completion.pct_w)
  )
  local max_height = math.min(
    CONFIG.completion.max_h,
    math.floor(vim.o.lines * CONFIG.completion.pct_h)
  )
  return max_width, max_height
end

---@return integer, integer
M.get_doc_size = function()
  local max_width =
    math.min(CONFIG.doc.max_w, math.floor(vim.o.columns * CONFIG.doc.pct_w))
  local max_height =
    math.min(CONFIG.doc.max_h, math.floor(vim.o.lines * CONFIG.doc.pct_h))
  return max_width, max_height
end

return M
