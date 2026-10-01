local M = {
  capabilities = { toggle = false, install = true, reorder = false },
}

local function treesitter()
  local ok, module = pcall(require, "nvim-treesitter")
  if not ok then
    return nil
  end
  return module
end

local function installed_set()
  local module = treesitter()
  if not module or type(module.get_installed) ~= "function" then
    return nil
  end

  local ok, installed = pcall(module.get_installed, "parsers")
  if not ok then
    return nil
  end

  local result = {}
  for _, name in ipairs(installed or {}) do
    result[name] = true
  end
  return result
end

---@param opts Tool.StatusOpts
---@return string, string
function M.entry_status(opts)
  local installed = installed_set()
  if not installed then
    return "treesitter unavailable", "DiagnosticWarn"
  elseif installed[opts.name] then
    return "installed", "DiagnosticOk"
  end
  return "not installed", "DiagnosticError"
end

---@param name string
---@param on_done fun()?
---@return boolean
function M.install(name, on_done)
  local module = treesitter()
  if not module or type(module.install) ~= "function" then
    local err = "nvim-treesitter is unavailable"
    vim.notify("ToolManager: " .. err, vim.log.levels.WARN)
    if on_done then
      on_done(false, err)
    end
    return false
  end

  local ok, task = pcall(module.install, { name })
  if not ok then
    if on_done then
      on_done(false, tostring(task))
    end
    return false
  end
  vim.notify(
    "Installing Treesitter parser " .. name .. "…",
    vim.log.levels.INFO
  )
  if not task or type(task.await) ~= "function" then
    local err = "nvim-treesitter returned no install task"
    vim.notify("ToolManager: " .. err, vim.log.levels.ERROR)
    if on_done then
      on_done(false, err)
    end
    return false
  end

  task:await(vim.schedule_wrap(function(err, installed)
    if err or installed ~= true then
      local message = err or "installation failed"
      vim.notify(
        "Failed to install Treesitter parser " .. name,
        vim.log.levels.ERROR
      )
      if on_done then
        on_done(false, message)
      end
    elseif on_done then
      on_done(true)
    end
  end))
  return true
end

---@param definitions table<string, Tool.Definition>
---@return { total: integer, installed: integer, missing: integer }
function M.summary(definitions)
  local installed = installed_set() or {}
  local total = vim.tbl_count(definitions)
  local count = 0
  for name in pairs(definitions) do
    if installed[name] then
      count = count + 1
    end
  end
  return { total = total, installed = count, missing = total - count }
end

return M
