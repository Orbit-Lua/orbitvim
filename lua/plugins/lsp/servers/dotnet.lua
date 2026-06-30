-- https://www.lazyvim.org/extras/lang/omnisharp
-- https://github.com/Hoffs/omnisharp-extended-lsp.nvim
-- wiki:
-- -> https://github.com/seblyng/roslyn.nvim/wiki
-- diagnostic hack:
-- -> https://github.com/seblyng/roslyn.nvim/blob/7d8819239c5e2c4a0d8150da1c00fa583f761704/lsp/roslyn.lua#L33

-- NOTE: official roslyn language server
-- https://github.com/dotnet/roslyn/tree/main/src/LanguageServer/Microsoft.CodeAnalysis.LanguageServer
--
local fs = require("utils.fs")

---@type Lsp.Server.Module
return {
  servers = {

    -- do net alter cmd, on_init, becase roslyn.nvim will handle it, and it will cause issues if we do
    -- refer to config example: https://github.com/seblyng/roslyn.nvim#example
    roslyn = {
      -- cmd = {
      --   "roslyn",
      --   "--logLevel=Information",
      --   "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.log.get_filename()),
      --   "--stdio",
      -- },

      on_attach = function(client, _)
        if client:supports_method("textDocument/semanticTokens") then
          client.server_capabilities.semanticTokensProvider = nil
        end
        -- local on_attach = function(client, bufnr)
        --   if client.server_capabilities.semanticTokensProvider then
        --     vim.treesitter.stop(bufnr)
        --   end
        -- end
      end,

      settings = {
        ["csharp|inlay_hints"] = {
          csharp_enable_inlay_hints_for_implicit_object_creation = true,
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
          csharp_enable_inlay_hints_for_lambda_parameter_types = true,
          csharp_enable_inlay_hints_for_types = true,
          dotnet_enable_inlay_hints_for_indexer_parameters = true,
          dotnet_enable_inlay_hints_for_literal_parameters = true,
          dotnet_enable_inlay_hints_for_object_creation_parameters = true,
          dotnet_enable_inlay_hints_for_other_parameters = true,
          dotnet_enable_inlay_hints_for_parameters = true,
          dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
          dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
          dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
        },
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = true,
        },

        ["csharp|background_analysis"] = {
          dotnet_analyzer_diagnostics_scope = "openFiles",
          dotnet_compiler_diagnostics_scope = "fullSolution",
        },

        ["csharp|symbol_search"] = {
          dotnet_search_reference_assemblies = true,
        },

        ["csharp|completion"] = {
          dotnet_show_name_completion_suggestions = true,
          dotnet_show_completion_items_from_unimported_namespaces = true,
          dotnet_provide_regex_completions = true,
        },
      },
    },
  },
}
