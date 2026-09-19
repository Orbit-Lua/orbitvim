---@module "lspconfig"

---@type Lsp.Config.Spec
local spec = require("config.lsp.servers.base")

local server_modules = {
  "config.lsp.servers.luals",
  "config.lsp.servers.markup",
  "config.lsp.servers.typescript",
  "config.lsp.servers.python",
  "config.lsp.servers.dotnet",
  "config.lsp.servers.misc",
}

for _, mod_name in ipairs(server_modules) do
  local mod = require(mod_name)
  spec.servers = vim.tbl_deep_extend("force", spec.servers, mod.servers or {})
  spec.setup = vim.tbl_deep_extend("force", spec.setup, mod.setup or {})
end

return spec
