local lsp = require("utils.lsp")

local data_path = vim.fs.normalize(vim.fn.stdpath("data"))

---@type Lsp.Server.Module
return {
  servers = {
    ruff = {
      cmd_env = { RUFF_TRACE = "messages" },
      init_options = {
        settings = {
          logLevel = "error",
          ["line-length"] = 80,
          exclude = { "**/__init__.py" },
          lint = {
            ignore = { "F403", "E402" },
          },
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
    -- NOTE: when [tool.pyright] is defined in pyproject.toml these defaults are overridden.
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
            include = { "src" },
            extraPaths = { "typings" },

            -- fix completion delay: https://github.com/microsoft/pyright/issues/4878
            useLibraryCodeForTypes = true,
            stubPath = data_path .. "/lazy/python-type-stubs/stubs",

            typeCheckingMode = "standard",
          },
        },
      },
    },

    -- config: https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
    pylsp = {
      settings = {
        plugins = {
          jedi_completion = { fuzzy = true },
          pycodestyle = { maxLineLength = 80 },
          signature = { formatter = "ruff", line_length = 100 },
        },
      },
    },

    -- config: https://github.com/pappasam/jedi-language-server?tab=readme-ov-file#configuration
    jedi_language_server = {
      init_options = {
        hover = { enable = true },
      },
    },
  },

  setup = {
    ruff = function()
      lsp.on_attach(function(client, _)
        -- Disable hover in favor of Pyright
        client.server_capabilities.hoverProvider = false
      end, "ruff")
    end,
  },
}
