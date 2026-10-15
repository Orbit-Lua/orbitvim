local ft = require("utils.ft")
local utils_table = require("utils.table")
local fs = require("utils.fs")

return {
  filetypes = ft.ts,

  ---@param client vim.lsp.Client
  on_attach = function(client, _)
    client.server_capabilities.semanticTokensProvider = nil
  end,

  handlers = {
    -- Drop duplicated diagnostic message
    -- https://neovim.io/doc/user/lsp.html#lsp-handler
    ---@type lsp.Handler
    ["textDocument/publishDiagnostics"] = function(err, res, ctx)
      local filtered = {}
      res.diagnostics = utils_table.unique_by_key(res.diagnostics, "message")
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
}
