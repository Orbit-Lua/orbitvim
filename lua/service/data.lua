local M = {}

local services = require("config.services")
local order = require("service.order")
local mason = require("service.mason")
local state_mod = require("service.state")
local category_handlers = require("service.category")

local function with_install_state(status_text, installed)
  if installed == true then
    return status_text .. " · installed"
  elseif installed == nil then
    return status_text .. " · external"
  end
  return status_text
end

---@param category ServiceCategory
---@param name string
---@param meta Service.Meta
---@return string status_text, string highlight_group
function M.entry_status(category, name, meta)
  if not state_mod.is_enabled(category, name) then
    return "disabled", "Comment"
  end

  local installed
  local install_error
  if meta.mason then
    installed, install_error = mason.package_status(meta.mason)
  end

  local status_text, highlight_group
  if install_error then
    if install_error:match("registry") then
      status_text = "mason unavailable"
    else
      status_text = "package missing"
    end
    highlight_group = "DiagnosticWarn"
  elseif not meta.mason then
    status_text, highlight_group = "external", "DiagnosticInfo"
  elseif installed == nil then
    status_text, highlight_group = "unknown", "DiagnosticWarn"
  elseif installed then
    status_text, highlight_group = "installed", "DiagnosticOk"
  else
    status_text, highlight_group = "not installed", "DiagnosticError"
  end

  if not install_error and installed ~= false then
    local handler = category_handlers[category]
    if handler then
      local refined_text, refined_hl = handler.entry_status({
        name = name,
        meta = meta,
        installed = installed,
      })
      if refined_text then
        status_text = with_install_state(refined_text, installed)
        highlight_group = refined_hl
      end
    end
  end

  return status_text, highlight_group
end

---@param category ServiceCategory
---@return Service.FtGroup[]
function M.build_ft_groups(category)
  return order.build_ft_groups(category)
end

---@param category ServiceCategory
---@return integer
function M.content_lines(category)
  if category == "lsp" or category == "dap" then
    return vim.tbl_count(services[category])
  end
  local h = 0
  for _, group in ipairs(M.build_ft_groups(category)) do
    h = h + 1 + #group.names
  end
  return h
end

return M
