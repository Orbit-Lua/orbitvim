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

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  once = true,
  callback = function()
    vim.api.nvim_create_user_command("ToolManager", function()
      require("tool").open()
    end, { desc = "Open Tool Manager" })
    vim.keymap.set(
      "n",
      "<leader>us",
      "<cmd>ToolManager<CR>",
      { desc = "tool manager" }
    )
  end,
})

return specs
