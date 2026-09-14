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

---Returns the current date as a formatted string.
---@param fmt? string `os.date` format string (default: `"%Y-%m-%d"`)
---@return string
M.get_current_date = function(fmt)
  local format = (fmt or "%Y-%m-%d"):gsub("%%s", tostring(os.time()))
  return os.date(format) --[[@as string]]
end

---Returns the current time as a formatted string.
---@param fmt? string `os.date` format string (default: `"%H:%M:%S"`)
---@return string
M.get_current_time = function(fmt)
  local format = (fmt or "%H:%M:%S"):gsub("%%s", tostring(os.time()))
  return os.date(format) --[[@as string]]
end

---Returns the current date and time as a formatted string.
---@param fmt? string `os.date` format string (default: `"%Y-%m-%d %H:%M:%S"`)
---@return string
M.get_datetime = function(fmt)
  -- %s is a POSIX extension unsupported by os.date on Windows; substitute directly.
  local format = (fmt or "%Y-%m-%d %H:%M:%S"):gsub("%%s", tostring(os.time()))
  return os.date(format) --[[@as string]]
end

-- ── Environment ───────────────────────────────────────────────────────────────

---Returns the value of an environment variable, or `nil` if unset.
---@param name string
---@return string | nil
M.get_env = function(name)
  return vim.uv.os_getenv(name)
end

-- ── Host / user ───────────────────────────────────────────────────────────────

---Returns the hostname of the machine, or `nil` on failure.
---@return string | nil
M.get_hostname = function()
  return vim.uv.os_gethostname()
end

---Returns the current OS username, or `nil` on failure.
---@return string | nil
M.get_username = function()
  local ok, passwd = pcall(vim.uv.os_get_passwd)
  if ok and passwd and passwd.username then
    return passwd.username
  end
  return vim.uv.os_getenv(M.is_win() and "USERNAME" or "USER")
end

return M
