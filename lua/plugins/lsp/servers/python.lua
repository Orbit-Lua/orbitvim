local lsp = require("utils.lsp")

local data_path = vim.fs.normalize(vim.fn.stdpath("data"))

---@type Lsp.Server.Module
return {
  servers = {
    ruff = {
      init_options = {
        settings = { configurationPreference = "filesystemFirst" },
      },
      keys = {
        {
          "<leader>co",
          lsp.action["source.organizeImports"],
          desc = "organize imports",
        },
      },
    },

    pyright = {
      settings = {
        pyright = {
          disableOrganizeImports = true,
          reportMissingTypeStubs = false,
        },
        python = {
          analysis = {
            autoSearchPaths = true,
            diagnosticMode = "workspace",
            include = { "src" },
            extraPaths = { "typings" },
            useLibraryCodeForTypes = true,
            stubPath = data_path .. "/lazy/python-type-stubs/stubs",
            typeCheckingMode = "standard",
          },
        },
      },
    },
  },

  setup = {
    ruff = function()
      lsp.on_attach(function(client, _)
        client.server_capabilities.hoverProvider = false
      end, "ruff")
    end,
  },
}
