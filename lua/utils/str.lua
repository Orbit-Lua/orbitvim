local M = {}

---@param s string
---@return string
---@return integer count
M.rstrip_slash = function(s)
  return s:gsub("/+$", "")
end

return M
