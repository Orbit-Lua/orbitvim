local M = {}

function M.setup()
  vim.api.nvim_create_user_command("Hangar", function()
    require("hangar").open()
  end, { desc = "Open Hangar" })
  vim.keymap.set("n", "<leader>us", "<cmd>Hangar<CR>", {
    desc = "hangar",
  })
end

return M
