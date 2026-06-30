---@alias Dap.Adapters table<string, any>
---@alias Dap.Configurations table<string, table[]>

---@class Dap.Spec
---@field adapters       Dap.Adapters
---@field configurations Dap.Configurations
---@field available_adapters Dap.Adapters
---@field available_configurations Dap.Configurations

---@class Dap.Module
---@field adapters?       Dap.Adapters
---@field configurations? Dap.Configurations

local modules = {
  "plugins.debugger.python",
  "plugins.debugger.dotnet",
}

local state_mod = require("service.state")

---@type Dap.Spec
local spec = {
  adapters = {},
  configurations = {},
  available_adapters = {},
  available_configurations = {},
}

local function add_configurations(target, source, predicate)
  for ft, configurations in pairs(source or {}) do
    target[ft] = target[ft] or {}
    for _, configuration in ipairs(configurations) do
      if predicate(configuration) then
        table.insert(target[ft], vim.deepcopy(configuration))
      end
    end
  end
end

for _, mod_name in ipairs(modules) do
  local mod = require(mod_name)
  for name, adapter in pairs(mod.adapters or {}) do
    spec.available_adapters[name] = adapter
    if state_mod.is_enabled("dap", name) then
      spec.adapters[name] = adapter
    end
  end
  add_configurations(
    spec.available_configurations,
    mod.configurations,
    function()
      return true
    end
  )
  add_configurations(
    spec.configurations,
    mod.configurations,
    function(configuration)
      return configuration.type == nil
        or state_mod.is_enabled("dap", configuration.type)
    end
  )
end

return spec
