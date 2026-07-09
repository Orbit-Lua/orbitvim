local M = {}

---@param override? lsp.ClientCapabilities
---@param include_nvim_defaults? boolean
M.get_lsp_capabilities = function(override, include_nvim_defaults)
  ---@type lsp.ClientCapabilities
  return vim.tbl_deep_extend(
    "force",
    include_nvim_defaults and vim.lsp.protocol.make_client_capabilities() or {},
    {
      textDocument = {
        completion = {
          completionItem = {
            snippetSupport = true,
            commitCharactersSupport = false, -- todo:
            documentationFormat = { "markdown", "plaintext" },
            deprecatedSupport = true,
            preselectSupport = false, -- todo:
            tagSupport = { valueSet = { 1 } }, -- deprecated
            insertReplaceSupport = true, -- todo:
            resolveSupport = {
              properties = {
                "documentation",
                "detail",
                "additionalTextEdits",
                "command",
                "data",
                -- todo: support more properties? should test if it improves latency
              },
            },
            insertTextModeSupport = {
              -- todo: support adjustIndentation
              valueSet = { 1 }, -- asIs
            },
            labelDetailsSupport = true,
          },
          completionList = {
            itemDefaults = {
              "commitCharacters",
              "editRange",
              "insertTextFormat",
              "insertTextMode",
              "data",
            },
          },

          contextSupport = true,
          insertTextMode = 1, -- asIs
        },
      },
    },
    override or {}
  )
end

return M
