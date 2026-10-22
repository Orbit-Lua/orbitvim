local ft = require("utils.ft")

---@type LazySpec[]
return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    init = function()
      require("core.theme").load_cache("mason")
    end,
    opts = function()
      return require("config.lsp.mason")
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "VeryLazy" },

    opts = function()
      return require("config.lsp")
    end,

    ---@module "config.lsp"
    ---@param _ LazyPlugin
    ---@param opts Lsp.Config.Spec
    config = function(_, opts)
      require("runtime.lsp").setup(opts)
    end,
  },

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
      local server = require("utils.os").is_win()
          and "roslyn-language-server.cmd"
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
