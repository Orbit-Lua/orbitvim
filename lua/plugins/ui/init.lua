---@type LazySpec[]
local specs = {}

for _, mod_name in ipairs({
  "plugins.ui.nvui",
  "plugins.ui.menu",
  "plugins.ui.snacks",
  "plugins.ui.noice",
  "plugins.ui.trouble",
  "plugins.ui.dotnet",
  "plugins.ui.which-key",
  "plugins.ui.edgy",
}) do
  vim.list_extend(specs, require(mod_name))
end

return specs
