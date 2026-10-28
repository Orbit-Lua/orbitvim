local M = {}

function M.setup()
  vim.api.nvim_create_user_command("ToolManager", function()
    require("hangar").open()
  end, { desc = "Open Tool Manager" })
  vim.keymap.set("n", "<leader>us", "<cmd>ToolManager<CR>", {
    desc = "tool manager",
  })
end

return M
