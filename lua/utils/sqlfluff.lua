local M = {}

local fs = require("utils.fs")

M.fallback_config = fs.config_path .. "/lua/config/db/template/sqlfluff.cfg"

---@param filename? string
---@return string
local function file_dir(filename)
  if not filename or filename == "" then
    return fs.get_cwd()
  end
  return vim.fn.fnamemodify(filename, ":p:h")
end

---@param filename? string
---@return string?
function M.find_config(filename)
  local candidates = vim.fs.find(fs.sqlfluff_pattern, {
    path = file_dir(filename),
    upward = true,
    type = "file",
    limit = math.huge,
  })

  for _, path in ipairs(candidates) do
    local is_toml = vim.fs.basename(path) == "pyproject.toml"
    for _, line in ipairs(vim.fn.readfile(path)) do
      local has_section
      if is_toml then
        has_section = line:find("^%s*%[tool%.sqlfluff%]")
          or line:find("^%s*%[tool%.sqlfluff%.")
      else
        has_section = line:find("^%s*%[sqlfluff%]")
          or line:find("^%s*%[sqlfluff:")
      end
      if has_section then
        return path
      end
    end
  end
end

---@param filename? string
---@return string
function M.cwd(filename)
  if not filename or filename == "" then
    return fs.get_root()
  end
  return fs.get_root(filename)
end

---@param command "format"|"lint"
---@param filename? string
---@return string[]
local function args(command, filename)
  local result = { command }
  if command == "lint" then
    vim.list_extend(result, { "--format=json" })
  end
  if filename and filename ~= "" then
    vim.list_extend(result, { "--stdin-filename", filename })
  end
  if not M.find_config(filename) then
    vim.list_extend(result, { "--config", M.fallback_config })
  end
  table.insert(result, "-")
  return result
end

---@param filename? string
---@return string[]
function M.format_args(filename)
  return args("format", filename)
end

---@param filename? string
---@return string[]
function M.lint_args(filename)
  return args("lint", filename)
end

return M
