local utils_lsp = require("utils.lsp")
local ft = require("utils.ft")
local icons = require("config.icons")

---@type LazySpec[]
return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    init = function()
      require("core.theme").load_cache("mason")
    end,
    opts = {
      PATH = "skip",

      ui = {
        icons = {
          package_pending = icons.mason.package_pending,
          package_installed = icons.mason.package_installed,
          package_uninstalled = icons.mason.package_uninstalled,
        },
      },

      max_concurrent_installers = 10,

      registries = {
        "github:mason-org/mason-registry",
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "VeryLazy" },

    opts = function()
      return require("config.lsp.config")
    end,

    ---@module "config.lsp.config"
    ---@param _ LazyPlugin
    ---@param opts Lsp.Config.Spec
    config = function(_, opts)
      local setup = require("runtime.lsp")

      utils_lsp.setup()
      utils_lsp.on_attach(function(client, buffer)
        require("runtime.lsp.keymaps").on_attach(client, buffer)
      end)
      utils_lsp.on_dynamic_capability(require("runtime.lsp.keymaps").on_attach)

      setup.configure_diagnostics(opts)
      setup.install_diagnostic_filter()
      setup.activate_features(opts)
      setup.register_servers(opts)
    end,
  },

  { "microsoft/python-type-stubs" },

  -- https://github.com/seblyng/roslyn.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
  {
    "seblyng/roslyn.nvim",
    -- Load before FileType so Roslyn's target options exist before LSP activation.
    event = { "BufReadPre *.cs", "BufNewFile *.cs" },
    ft = { "cs" },
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = function()
      return require("config.lsp.roslyn")
    end,
    cond = function()
      local server = vim.fn.has("win32") == 1 and "roslyn-language-server.cmd"
        or "roslyn-language-server"
      return vim.fn.executable("dotnet") == 1 and vim.fn.executable(server) == 1
    end,
  },

  {
    "pmizio/typescript-tools.nvim",
    ft = ft.ts,
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    -- https://github.com/pmizio/typescript-tools.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
    opts = function()
      return require("config.lsp.typescript_tools")
    end,
  },
}
