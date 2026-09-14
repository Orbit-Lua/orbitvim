local utils_lsp = require("utils.lsp")
local ft = require("utils.ft")
local fs = require("utils.fs")
local theme = require("config.theme")
local icons = require("config").icons

theme.load_cache("mason")

local function unique_by_key(items, key)
  local seen = {}
  local result = {}
  for _, item in ipairs(items or {}) do
    local value = item[key]
    if not seen[value] then
      seen[value] = true
      table.insert(result, item)
    end
  end
  return result
end

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
    event = { "VeryLazy" },
    opts = function()
      return require("plugins.lsp.config")
    end,
    config = function(_, opts)
      local setup = require("plugins.lsp.setup")
      utils_lsp.setup()
      utils_lsp.on_attach(function(client, buffer)
        require("plugins.lsp.keymaps").on_attach(client, buffer)
      end)
      utils_lsp.on_dynamic_capability(require("plugins.lsp.keymaps").on_attach)
      setup.configure_diagnostics(opts)
      setup.install_diagnostic_filter()
      setup.activate_features(opts)
      setup.register_servers(opts)
    end,
  },

  { "microsoft/python-type-stubs" },

  {
    "seblyng/roslyn.nvim",
    ft = { "cs" },
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
    opts = {
      filetypes = ft.ts,
      on_attach = function(client, _)
        client.server_capabilities.semanticTokensProvider = nil
      end,
      handlers = {
        ["textDocument/publishDiagnostics"] = function(err, res, ctx)
          if not res then
            return
          end
          local filtered = {}
          for _, diagnostic in ipairs(unique_by_key(res.diagnostics, "message")) do
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
        tsserver_file_preferences = {
          includeCompletionsForModuleExports = true,
          quotePreference = "auto",
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHintsWhenTypeMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayEnumMemberValueHints = true,
          includeInlayParameterNameHints = "literals",
          includeInlayVariableTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
        },
      },
    },
  },
}
