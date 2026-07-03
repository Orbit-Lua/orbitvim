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

    -- copilot.lua only works with its own copilot lsp server
    copilot = { enabled = false },

    -- config ref: https://github.com/eclipse-lemminx/lemminx/blob/main/docs/Configuration.md
    lemminx = {
      settings = {
        xml = {
          fileAssociations = {
            {
              systemId = fs.schema_paths.ms_build,
              pattern = "**/*.csproj",
            },
          },
          completion = {
            autoCloseTags = true,
          },
          validation = {
            enabled = false,
          },
        },
      },
    },
  },
}
