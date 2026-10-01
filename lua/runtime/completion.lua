local M = {}

function M.create_undo()
  if vim.api.nvim_get_mode().mode == "i" then
    local keys = vim.api.nvim_replace_termcodes("<C-g>u", true, true, true)
    vim.api.nvim_feedkeys(keys, "n", false)
  end
end

function M.setup_luasnip(opts)
  local luasnip = require("luasnip")
  luasnip.config.set_config(opts)
  luasnip.filetype_extend("jsx", { "javascript", "javascriptreact" })
  luasnip.filetype_extend("sql", { "tsql" })
  require("runtime.snippets").setup()
end

return M
