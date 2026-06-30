---@module "lspconfig"

---@type Lsp.Config.Spec
local spec = require("plugins.lsp.servers.base")

local server_modules = {
  "plugins.lsp.servers.lua_ls",
  "plugins.lsp.servers.typescript",
  "plugins.lsp.servers.python",
  "plugins.lsp.servers.dotnet",
  "plugins.lsp.servers.misc",
}

for _, mod_name in ipairs(server_modules) do
  local mod = require(mod_name)
  spec.servers = vim.tbl_deep_extend("force", spec.servers, mod.servers or {})
  spec.setup = vim.tbl_deep_extend("force", spec.setup, mod.setup or {})
end

return spec
