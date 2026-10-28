---@module "lspconfig"

---@type Lsp.Config.Spec
local spec = vim.deepcopy(require("features.lsp.config.servers.base"))

local server_modules = {
  "features.lsp.config.servers.luals",
  "features.lsp.config.servers.markup",
  "features.lsp.config.servers.typescript",
  "features.lsp.config.servers.python",
  "features.lsp.config.servers.dotnet",
  "features.lsp.config.servers.misc",
}

for _, module_name in ipairs(server_modules) do
  local module = require(module_name)
  spec.servers =
    vim.tbl_deep_extend("force", spec.servers, module.servers or {})
  spec.setup = vim.tbl_deep_extend("force", spec.setup, module.setup or {})
end

for name, options in
  pairs(require("features.settings.config").get().lsp.servers)
do
  spec.servers[name] =
    vim.tbl_deep_extend("force", spec.servers[name] or {}, options)
end

return spec
