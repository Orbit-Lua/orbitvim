local M = {
  capabilities = { toggle = false, install = true, reorder = false },
}

local mason = require("tool.mason")

---@param opts Tool.StatusOpts
---@return string, string
function M.entry_status(opts)
  local installed, err = mason.package_status(opts.name)
  if err then
    return err:match("registry") and "mason unavailable" or "package missing",
      "DiagnosticWarn"
  elseif installed then
    return "installed", "DiagnosticOk"
  end
  return "not installed", "DiagnosticError"
end

---@param name string
---@param on_done fun()?
---@return boolean
function M.install(name, on_done)
  return mason.install(name, on_done)
end

---@param definitions table<string, Tool.Definition>
---@return { total: integer, installed: integer, missing: integer }
function M.summary(definitions)
  local total = vim.tbl_count(definitions)
  local count = 0
  for name in pairs(definitions) do
    if mason.package_status(name) == true then
      count = count + 1
    end
  end
  return { total = total, installed = count, missing = total - count }
end

return M
