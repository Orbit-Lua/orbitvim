local M = {}

---@param pkg_name string
---@return table? pkg, string? err
function M.get_package(pkg_name)
  local reg_ok, reg = pcall(require, "mason-registry")
  if not reg_ok then
    return nil, "mason registry is unavailable"
  end

  local pkg_ok, pkg = pcall(reg.get_package, pkg_name)
  if not pkg_ok or not pkg then
    return nil, "mason package not found: " .. pkg_name
  end

  return pkg, nil
end

---@param pkg_name string
---@return boolean? installed, string? err
function M.package_status(pkg_name)
  local pkg, err = M.get_package(pkg_name)
  if not pkg then
    return nil, err
  end
  return pkg:is_installed(), nil
end

---@param pkg_name string?
---@param on_done (fun())?
---@return boolean
function M.install(pkg_name, on_done)
  if not pkg_name then
    return false
  end

  local pkg, err = M.get_package(pkg_name)
  if not pkg then
    vim.notify("ServiceManager: " .. err, vim.log.levels.WARN)
    return false
  end

  if pkg:is_installed() then
    vim.notify(pkg_name .. " is already installed", vim.log.levels.INFO)
    if on_done then
      on_done()
    end
    return true
  end

  vim.notify("Installing " .. pkg_name .. "…", vim.log.levels.INFO)
  pkg:install():once("closed", function()
    if pkg:is_installed() then
      vim.schedule(function()
        vim.notify(pkg_name .. " installed", vim.log.levels.INFO)
        if on_done then
          on_done()
        end
      end)
    else
      vim.schedule(function()
        vim.notify("Failed to install " .. pkg_name, vim.log.levels.ERROR)
      end)
    end
  end)

  return true
end

return M
