-- https://www.lazyvim.org/extras/lang/omnisharp
-- https://github.com/Hoffs/omnisharp-extended-lsp.nvim
-- wiki:
-- -> https://github.com/seblyng/roslyn.nvim/wiki
-- diagnostic hack:
-- -> https://github.com/seblyng/roslyn.nvim/blob/7d8819239c5e2c4a0d8150da1c00fa583f761704/lsp/roslyn.lua#L33

---@type Lsp.Server.Module
return {
  servers = {

    roslyn = {
      -- Official roslyn language server
      -- https://github.com/dotnet/roslyn/tree/main/src/LanguageServer/Microsoft.CodeAnalysis.LanguageServer
      --
      -- do net alter cmd, on_init, becase roslyn.nvim will handle it, and it will cause issues if we do
      -- refer to config example: https://github.com/seblyng/roslyn.nvim#example
      --
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
      end,

      -- luacheck: ignore
      -- Schema: https://github.com/dotnet/vscode-csharp/blob/main/test/lsptoolshost/unitTests/configurationMiddleware.test.ts
      settings = {
        ["csharp|code_style"] = {
          formatting = {
            indentation_and_spacing = {
              -- codeStyle.formatting.indentationAndSpacing.indentSize: Indentation columns.
              indent_size = 4,
              -- codeStyle.formatting.indentationAndSpacing.indentStyle: Prefer spaces or tabs for indentation.
              indent_style = "space",
              -- codeStyle.formatting.indentationAndSpacing.tabWidth: Number of columns represented by a tab.
              tab_width = 4,
            },
            new_line = {
              -- codeStyle.formatting.newLine.endOfLine: End-of-line sequence used by formatting.
              end_of_line = "lf",
            },
          },
        },

        ["csharp|auto_insert"] = {
          -- dotnet.autoInsert.enableAutoInsert: Automatically adjust code constructs while typing.
          dotnet_enable_auto_insert = true,
        },

        ["csharp|background_analysis"] = {
          -- dotnet.backgroundAnalysis.analyzerDiagnosticsScope: Analyzer diagnostic scope.
          dotnet_analyzer_diagnostics_scope = "openFiles",
          -- dotnet.backgroundAnalysis.compilerDiagnosticsScope: Compiler diagnostic scope.
          dotnet_compiler_diagnostics_scope = "fullSolution",
        },

        ["csharp|code_lens"] = {
          -- dotnet.codeLens.enableReferencesCodeLens: Show references CodeLens.
          dotnet_enable_references_code_lens = true,
          -- dotnet.codeLens.enableTestsCodeLens: Show run and debug test CodeLens.
          dotnet_enable_tests_code_lens = true,
        },

        ["csharp|completion"] = {
          -- dotnet.completion.provideRegexCompletions: Show regular expressions in completion lists.
          dotnet_provide_regex_completions = true,
          -- dotnet.completion.showCompletionItemsFromUnimportedNamespaces: Include unimported symbols.
          dotnet_show_completion_items_from_unimported_namespaces = true,
          -- dotnet.completion.showNameCompletionSuggestions: Suggest object names based on recently selected members.
          dotnet_show_name_completion_suggestions = true,
          -- dotnet.completion.triggerCompletionInArgumentLists: Automatically open completion in argument lists.
          dotnet_trigger_completion_in_argument_lists = true,
        },

        ["csharp|diagnostics"] = {
          -- dotnet.diagnostics.reportInformationAsHint: Report information diagnostics as hints.
          dotnet_report_information_as_hint = true,
        },

        ["csharp|formatting"] = {
          -- dotnet.formatting.organizeImportsOnFormat: Sort and group using directives during formatting.
          dotnet_organize_imports_on_format = false,
        },

        ["csharp|highlighting"] = {
          -- dotnet.highlighting.highlightRelatedJsonComponents: Highlight related JSON components under the cursor.
          dotnet_highlight_related_json_components = true,
          -- dotnet.highlighting.highlightRelatedRegexComponents: Highlight related regex components under the cursor.
          dotnet_highlight_related_regex_components = true,
        },

        ["csharp|inlay_hints"] = {
          -- csharp.inlayHints.enableInlayHintsForImplicitObjectCreation: Show hints for implicit object creation.
          csharp_enable_inlay_hints_for_implicit_object_creation = true,
          -- csharp.inlayHints.enableInlayHintsForImplicitVariableTypes: Show hints for variables with inferred types.
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
          -- csharp.inlayHints.enableInlayHintsForLambdaParameterTypes: Show hints for lambda parameter types.
          csharp_enable_inlay_hints_for_lambda_parameter_types = true,
          -- csharp.inlayHints.enableInlayHintsForTypes: Show inline type hints.
          csharp_enable_inlay_hints_for_types = true,
          -- dotnet.inlayHints.enableInlayHintsForIndexerParameters: Show parameter hints for indexers.
          dotnet_enable_inlay_hints_for_indexer_parameters = true,
          -- dotnet.inlayHints.enableInlayHintsForLiteralParameters: Show parameter hints for literals.
          dotnet_enable_inlay_hints_for_literal_parameters = true,
          -- dotnet.inlayHints.enableInlayHintsForObjectCreationParameters: Show parameter hints for object creation.
          dotnet_enable_inlay_hints_for_object_creation_parameters = true,
          -- dotnet.inlayHints.enableInlayHintsForOtherParameters: Show parameter hints for other argument kinds.
          dotnet_enable_inlay_hints_for_other_parameters = true,
          -- dotnet.inlayHints.enableInlayHintsForParameters: Show inline parameter name hints.
          dotnet_enable_inlay_hints_for_parameters = true,
          -- dotnet.inlayHints.suppressInlayHintsForParametersThatDifferOnlyBySuffix: Hide suffix-only hints.
          dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
          -- dotnet.inlayHints.suppressInlayHintsForParametersThatMatchArgumentName: Hide matching-name hints.
          dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
          -- dotnet.inlayHints.suppressInlayHintsForParametersThatMatchMethodIntent: Hide method-intent hints.
          dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
        },

        ["csharp|quick_info"] = {
          -- dotnet.quickInfo.showRemarksInQuickInfo: Include remarks in Quick Info.
          dotnet_show_remarks_in_quick_info = true,
        },

        ["csharp|symbol_search"] = {
          -- dotnet.symbolSearch.searchReferenceAssemblies: Search references for symbols and add-imports.
          dotnet_search_reference_assemblies = true,
        },

        ["csharp|type_members"] = {
          -- dotnet.typeMembers.memberInsertionLocation: Where generated members are inserted.
          dotnet_member_insertion_location = "withOtherMembersOfTheSameKind",
          -- dotnet.typeMembers.propertyGenerationBehavior: Prefer throwing properties or auto-properties.
          dotnet_property_generation_behavior = "preferThrowingProperties",
        },

        code_style = {
          formatting = {
            new_line = {
              -- codeStyle.formatting.newLine.insertFinalNewline: Ensure final newline.
              insert_final_newline = true,
            },
          },
        },

        navigation = {
          -- dotnet.navigation.navigateToDecompiledSources: Allow navigation to decompiled sources.
          dotnet_navigate_to_decompiled_sources = true,
          -- dotnet.navigation.navigateToSourceLinkAndEmbeddedSources: Prefer linked or embedded sources.
          dotnet_navigate_to_source_link_and_embedded_sources = true,
        },

        text_editor = {
          -- textEditor.tabWidth: Editor tab width fallback used by server formatting options.
          tab_width = 4,
        },
      },
    },
  },
}
