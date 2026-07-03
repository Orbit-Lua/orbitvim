---@type LazySpec[]
local specs = {}

for _, mod_name in ipairs({
  "plugins.ui.nvui",
  "plugins.ui.snacks",
  "plugins.ui.noice",
  "plugins.ui.trouble",
  "plugins.ui.dotnet",
  "plugins.ui.which-key",
  "plugins.ui.edgy",
}) do
  vim.list_extend(specs, require(mod_name))
end

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  once = true,
  callback = function()
    vim.api.nvim_create_user_command("ServiceManager", function()
      require("service").open()
    end, { desc = "Open Service Manager" })
    vim.keymap.set(
      "n",
      "<leader>us",
      "<cmd>ServiceManager<CR>",
      { desc = "service manager" }
    )
  end,
})

return specs
