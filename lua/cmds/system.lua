local os_utils = require("utils.os")

if not os_utils.is_win() then
  return
end

-- NOTE: (temp): issue: https://github.com/neovim/neovim/issues/8587
-- this method is from: https://github.com/neovim/neovim/issues/8587#issuecomment-2176399196
vim.api.nvim_create_user_command("ClearShada", function()
  local shada_path = vim.fn.expand(vim.fn.stdpath("data") .. "/shada")
  require("utils.fs").delete_files(shada_path, {
    success_message = "Successfully deleted all temporary shada files",
    skip_condition = function(file_name)
      return file_name == "main.shada"
    end,
  })
end, { desc = "Clears all the .tmp shada files" })
