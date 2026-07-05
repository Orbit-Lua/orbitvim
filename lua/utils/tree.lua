local M = {}

---@return integer width of the neo-tree window, or 0 if not open
M.get_neo_tree_width = function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if bufname:match("neo%-tree filesystem") or bufname:match("neo%-tree") then
      return vim.api.nvim_win_get_width(win)
    end
  end

  return 0
end

---@return string statusline segment with neo-tree offset padding, or empty string
M.offset = function()
  local w = M.get_neo_tree_width()
  return w == 0 and ""
    or "%#NeoTreeNormal#"
      .. string.rep(" ", w)
      .. "%#NeoTreeWinSeparator#"
      .. "│"
end

return M
