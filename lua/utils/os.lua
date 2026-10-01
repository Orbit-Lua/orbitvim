local M = {}

-- ── OS detection ─────────────────────────────────────────────────────────────

---@return boolean
M.is_win = function()
  return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

---@return boolean
M.is_linux = function()
  return vim.uv.os_uname().sysname:find("Linux") ~= nil
end

-- ── Date / time ───────────────────────────────────────────────────────────────

---Returns the current date and time as a formatted string.
---@param fmt? string `os.date` format string (default: `"%Y-%m-%d %H:%M:%S"`)
---@return string
M.get_datetime = function(fmt)
  -- %s is a POSIX extension unsupported by os.date on Windows; substitute directly.
  local format = (fmt or "%Y-%m-%d %H:%M:%S"):gsub("%%s", tostring(os.time()))
  return os.date(format) --[[@as string]]
end

return M
