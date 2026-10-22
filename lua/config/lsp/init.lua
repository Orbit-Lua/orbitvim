---@module "lspconfig"

---@type Lsp.Config.Spec
local spec = vim.deepcopy(require("config.lsp.servers.base"))

local server_modules = {
  "config.lsp.servers.luals",
  "config.lsp.servers.markup",
  "config.lsp.servers.typescript",
  "config.lsp.servers.python",
  "config.lsp.servers.dotnet",
  "config.lsp.servers.misc",
}

for _, module_name in ipairs(server_modules) do
  local module = require(module_name)
  spec.servers =
    vim.tbl_deep_extend("force", spec.servers, module.servers or {})
  spec.setup = vim.tbl_deep_extend("force", spec.setup, module.setup or {})
end

for name, options in pairs(require("config.settings").get().lsp.servers) do
  spec.servers[name] =
    vim.tbl_deep_extend("force", spec.servers[name] or {}, options)
end

return spec
