---@type Lsp.Server.Module
return {
  servers = {
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
