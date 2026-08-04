local fs = require("utils.fs")

---@type Lsp.Server.Module
return {
  servers = {
    prismals = {
      keys = {
        {
          "<leader>fP",
          function()
            require("conform").format({ lsp_fallback = true })
            vim.cmd("e!")
          end,
          desc = "prisma format file and force reload",
        },
      },
    },

    powershell_es = {
      bundle_path = fs.mason_pkg_path .. "/powershell-editor-services",
      shell = "pwsh",
    },
  },
}
