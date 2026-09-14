---@alias Dap.Adapters table<string, any>
---@alias Dap.Configurations table<string, table[]>

---@class Dap.Spec
---@field adapters Dap.Adapters
---@field configurations Dap.Configurations

local modules = {
  "plugins.debugger.python",
  "plugins.debugger.dotnet",
}

---@type Dap.Spec
local spec = {
  adapters = {},
  configurations = {},
}

for _, mod_name in ipairs(modules) do
  local mod = require(mod_name)
  for name, adapter in pairs(mod.adapters or {}) do
    spec.adapters[name] = adapter
  end
  for filetype, configurations in pairs(mod.configurations or {}) do
    spec.configurations[filetype] = spec.configurations[filetype] or {}
    for _, configuration in ipairs(configurations) do
      table.insert(spec.configurations[filetype], vim.deepcopy(configuration))
    end
  end
end

return spec
