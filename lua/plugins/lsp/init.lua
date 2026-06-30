local utils_lsp = require("utils.lsp")
local ft = require("utils.ft")
local utils_table = require("utils.table")
local fs = require("utils.fs")
local ui = require("utils.ui")
local icons = require("config").icons

ui.load_base46_cache("mason")

---@type LazySpec[]
return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
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
        "github:Crashdummyy/mason-registry",
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufEnter", "BufReadPre" },

    opts = function()
      return require("plugins.lsp.config")
    end,

    ---@module "plugins.lsp.config"
    ---@param _ LazyPlugin
    ---@param opts Lsp.Config.Spec
    config = function(_, opts)
      local setup = require("plugins.lsp.setup")

      utils_lsp.on_attach(function(client, buffer)
        require("plugins.lsp.keymaps").on_attach(client, buffer)
      end)

      setup.register_servers(opts)
      utils_lsp.setup()
      utils_lsp.on_dynamic_capability(require("plugins.lsp.keymaps").on_attach)

      setup.configure_diagnostics(opts)
      setup.install_diagnostic_filter()
      setup.activate_features(opts)
    end,
  },

  { "microsoft/python-type-stubs" },

  -- https://github.com/seblyng/roslyn.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
  {
    "seblyng/roslyn.nvim",
    ft = { "cs" },
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
      filewatching = "roslyn",
      silent = true,
    },
    cond = function()
      return vim.fn.executable("dotnet") == 1
    end,
  },

  {
    "pmizio/typescript-tools.nvim",
    ft = ft.ts,
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    -- https://github.com/pmizio/typescript-tools.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
    opts = {
      filetypes = ft.ts,

      ---@param client vim.lsp.Client
      on_attach = function(client, _)
        client.server_capabilities.semanticTokensProvider = nil
      end,

      handlers = {
        -- HACK: drop duplicated diagnostic message
        -- https://neovim.io/doc/user/lsp.html#lsp-handler
        ---@type lsp.Handler
        ["textDocument/publishDiagnostics"] = function(err, res, ctx)
          local filtered = {}
          res.diagnostics =
            utils_table.unique_by_key(res.diagnostics, "message")
          for _, diagnostic in ipairs(res.diagnostics) do
            if diagnostic.source == "tsserver" then
              table.insert(filtered, diagnostic)
            end
          end

          res.diagnostics = filtered
          vim.lsp.diagnostic.on_publish_diagnostics(err, res, ctx)
        end,
      },

      settings = {
        separate_diagnostic_server = true,
        code_lens = "off",
        tsserver_path = fs.mason_pkg_path
          .. "/typescript-language-server/node_modules/typescript/lib/tsserver.js",

        -- https://github.com/microsoft/TypeScript/blob/v5.0.4/src/server/protocol.ts#L3439
        tsserver_file_preferences = {
          includeCompletionsForModuleExports = true,
          quotePreference = "auto",

          -- luacheck: push ignore
          --
          -- https://github.com/microsoft/TypeScript/blob/3b45f4db12bbae97d10f62ec0e2d94858252c5ab/src/server/protocol.ts#L3501
          --
          -- luacheck: pop
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHintsWhenTypeMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayEnumMemberValueHints = true,

          -- enable following inlay hints may crash the server
          -- includeInlayParameterNameHints = "none",
          includeInlayParameterNameHints = "literals",
          includeInlayVariableTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
        },
      },
    },
  },
}
