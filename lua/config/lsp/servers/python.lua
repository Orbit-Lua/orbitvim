local lsp = require("runtime.lsp.client")

---@type Lsp.Server.Module
return {
  servers = {
    ruff = {
      init_options = {
        settings = {
          configurationPreference = "filesystemFirst",
        },
      },
      keys = {
        {
          "<leader>co",
          lsp.action["source.organizeImports"],
          desc = "organize imports",
        },
      },
    },

    -- More settings: https://microsoft.github.io/pyright/#/settings
    -- When [tool.pyright] is defined in pyproject.toml these defaults are overridden.
    pyright = {
      settings = {
        pyright = {
          disableOrganizeImports = true, -- delegate to Ruff
          reportMissingTypeStubs = false,
        },

        python = {
          analysis = {
            autoSearchPaths = true,
            diagnosticMode = "workspace",
            useLibraryCodeForTypes = true,
            typeCheckingMode = "standard",
          },
        },
      },
    },
  },

  setup = {
    ruff = function()
      lsp.on_attach(
        function(client, _)
          -- Disable hover in favor of Pyright
          client.server_capabilities.hoverProvider = false
        end,
        "ruff",
        vim.api.nvim_create_augroup("OrbitVimRuffAttach", { clear = true })
      )
    end,
  },
}
