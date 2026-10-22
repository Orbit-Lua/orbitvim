local M = {}

function M.setup()
  vim.api.nvim_create_user_command("TSInstallAll", function()
    require("nvim-treesitter").install(
      vim.deepcopy(require("config.packages").treesitter_ensure_installed)
    )
  end, { desc = "Install all configured Treesitter parsers" })
end

return M
