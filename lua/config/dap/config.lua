---@alias Dap.Adapters table<string, any>
---@alias Dap.Configurations table<string, table[]>

---@class Dap.Spec
---@field adapters Dap.Adapters
---@field configurations Dap.Configurations

---@class Dap.Module
---@field adapters? Dap.Adapters
---@field configurations? Dap.Configurations

local modules = {
  "config.dap.python",
  "config.dap.dotnet",
}

local spec = {
  adapters = {},
  configurations = {},
}

for _, module_name in ipairs(modules) do
  local module = require(module_name)
  for name, adapter in pairs(module.adapters or {}) do
    spec.adapters[name] = adapter
  end
  for filetype, configurations in pairs(module.configurations or {}) do
    spec.configurations[filetype] = spec.configurations[filetype] or {}
    vim.list_extend(spec.configurations[filetype], vim.deepcopy(configurations))
  end
end

return spec
