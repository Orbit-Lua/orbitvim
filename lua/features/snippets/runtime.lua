local M = {}

function M.setup()
  -- OrbitVim's tsql collection replaces friendly-snippets' generic SQL.
  require("luasnip.loaders.from_vscode").lazy_load({ exclude = { "sql" } })
  require("luasnip.loaders.from_lua").load()

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = vim.api.nvim_create_augroup("OrbitVimSnippets", { clear = true }),
    callback = function()
      local luasnip = require("luasnip")
      if
        luasnip.session.current_nodes[vim.api.nvim_get_current_buf()]
        and not luasnip.session.jump_active
      then
        luasnip.unlink_current()
      end
    end,
  })
end

return M
