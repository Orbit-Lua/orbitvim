---@type Lsp.Server.Module
return {
  servers = {
    tailwindcss = {
      condition = function(bufnr)
        return require("utils.project").tool_root(
          vim.api.nvim_buf_get_name(bufnr),
          "tailwindcss"
        ) ~= nil
      end,
    },
    ["typescript-tools"] = {
      keys = {
        {
          "<leader>co",
          "<cmd>TSToolsOrganizeImports<cr>",
          desc = "organize imports",
        },
      },
    },
  },
}
