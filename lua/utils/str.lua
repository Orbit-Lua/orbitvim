local M = {}

---@param s string
---@return string
---@return integer count
M.rstrip_slash = function(s)
  return s:gsub("/+$", "")
end

---@param s string
---@param max_w integer
---@return string
M.trunc = function(s, max_w)
  local ellipsis = "…"
  if max_w <= 0 then
    return ""
  end
  if vim.fn.strdisplaywidth(s) <= max_w then
    return s
  end

  local ellipsis_w = vim.fn.strdisplaywidth(ellipsis)
  if max_w <= ellipsis_w then
    return vim.fn.strcharpart(ellipsis, 0, max_w)
  end

  local result = ""
  for i = 0, vim.fn.strchars(s) - 1 do
    local char = vim.fn.strcharpart(s, i, 1)
    local candidate = result .. char
    if vim.fn.strdisplaywidth(candidate) + ellipsis_w > max_w then
      break
    end
    result = candidate
  end

  return result .. ellipsis
end

---@param s string
---@param w integer
---@return string
M.rpad = function(s, w)
  local dw = vim.fn.strdisplaywidth(s)
  return dw < w and (s .. string.rep(" ", w - dw)) or s
end

---Pad `s` with trailing spaces to fill `inner_w` display columns.
---@param s string
---@param inner_w integer
---@return string
M.fill_line = function(s, inner_w)
  return M.rpad(s, inner_w)
end

return M
