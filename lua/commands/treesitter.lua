local M = {}

function M.setup()
  vim.api.nvim_create_user_command("TSInstallAll", function()
    local spec = require("lazy.core.config").plugins["nvim-treesitter"]
    local opts = type(spec.opts) == "table" and spec.opts or {}
    require("nvim-treesitter").install(opts.ensure_installed)
  end, { desc = "Install all configured Treesitter parsers" })
end

return M
