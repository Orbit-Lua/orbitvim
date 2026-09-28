local M = {}

function M.setup_luasnip(opts)
  local luasnip = require("luasnip")
  luasnip.config.set_config(opts)
  luasnip.filetype_extend("jsx", { "javascript", "javascriptreact" })
  luasnip.filetype_extend("sql", { "tsql" })
  require("runtime.snippets").setup()
end

return M
