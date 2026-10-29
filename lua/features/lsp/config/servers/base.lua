---@module "lspconfig"

---@class Lsp.Config.Servers
---@field [string] vim.lsp.Config | {keys?: LazyKeysSpec[], condition?: fun(bufnr: integer): boolean}

---@class Lsp.Config.Spec
---@field servers Lsp.Config.Servers
---
---default lsp config for all servers
---@field on_init elem_or_list<fun(client: vim.lsp.Client, init_result: lsp.InitializeResult)>
---@field capabilities lsp.ClientCapabilities
---
---@field disable_default_settings {[string]: table}
---@field setup {[string]: fun()}
---@field diagnostics vim.diagnostic.Opts
---@field inlay_hints {enabled: boolean, exclude: table}
---@field codelens {enabled: boolean}

---@class Lsp.Server.Module
---@field servers? Lsp.Config.Servers
---@field setup? {[string]: fun()}

local icons = require("shared.icons")
local borders = require("shared.borders")

---@type Lsp.Config.Spec
return {
  diagnostics = {
    underline = true,
    update_in_insert = false,

    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
      severity = {
        min = vim.diagnostic.severity.WARN,
      },
    },

    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = icons.diagnostics.error,
        [vim.diagnostic.severity.WARN] = icons.diagnostics.warning,
        [vim.diagnostic.severity.HINT] = icons.diagnostics.hint,
        [vim.diagnostic.severity.INFO] = icons.diagnostics.info,
      },
    },

    float = {
      border = borders.lsp_diagnostic,
    },
  },

  inlay_hints = require("features.settings.config").get().lsp.inlay_hints,
  codelens = require("features.settings.config").get().lsp.codelens,

  -- Tree-sitter owns highlighting.
  on_init = function(client, _)
    client.server_capabilities.semanticTokensProvider = nil
  end,

  -- Overrides applied on top of the completion engine's client capabilities.
  capabilities = {
    textDocument = {
      diagnostic = {
        dynamicRegistration = true,
      },
    },
    window = {
      workDoneProgress = true,
    },
  },

  disable_default_settings = {
    roslyn = { "on_init" },
  },

  servers = {},
  setup = {},
}
