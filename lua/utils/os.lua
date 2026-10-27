local M = {}

-- ── OS detection ─────────────────────────────────────────────────────────────

local windows = vim.fn.has("win32") == 1
local mac = vim.fn.has("mac") == 1
local arm64 = vim.uv.os_uname().machine == "arm64"

---@return boolean
M.is_win = function()
  return windows
end

---@return boolean
M.is_mac = function()
  return mac
end

---@return boolean
M.is_arm64 = function()
  return arm64
end

---Separator between entries of the PATH environment variable.
---@return string
M.path_delimiter = function()
  return M.is_win() and ";" or ":"
end

---First PATH match for an executable, skipping one directory.
---@param name string executable name without a Windows extension
---@param opts? { exclude?: string } directory to skip
---@return string?
M.find_executable = function(name, opts)
  local function comparable(path)
    path = vim.fs.normalize(path)
    return M.is_win() and path:lower() or path
  end
  local excluded = opts and opts.exclude and comparable(opts.exclude)
  local names = M.is_win()
      and { name .. ".exe", name .. ".bat", name .. ".cmd" }
    or { name }
  local directories =
    vim.split(vim.env.PATH or "", M.path_delimiter(), { trimempty = true })
  for _, directory in ipairs(directories) do
    if comparable(directory) ~= excluded then
      for _, candidate in ipairs(names) do
        local path = directory .. "/" .. candidate
        if vim.fn.executable(path) == 1 then
          return path
        end
      end
    end
  end
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
