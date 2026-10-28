local fs = require("utils.fs")

---@type Lsp.Server.Module
return {
  servers = {
    prismals = {
      keys = {
        {
          "<leader>fP",
          function()
            require("features.formatter.runtime").format()
          end,
          desc = "prisma format buffer",
        },
      },
    },

    powershell_es = {
      bundle_path = fs.mason_pkg_path .. "/powershell-editor-services",
      shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell",
    },
  },
}
