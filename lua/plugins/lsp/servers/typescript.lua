local lsp = require("utils.lsp")
local ft = require("utils.ft")
local utils = require("utils")

-- https://github.com/yioneko/vtsls/blob/main/packages/service/configuration.schema.json
---@type Lsp.Server.Module
return {
  servers = {
    vtsls = {
      filetypes = ft.ts,
      settings = {
        vtsls = {
          enableMoveToFileCodeAction = true,
          autoUseWorkspaceTsdk = true,
          experimental = {
            maxInlayHintLength = nil,
            completion = {
              entriesLimit = 50,
              enableServerSideFuzzyMatch = true,
            },
          },
        },
        typescript = {
          tsserver = {
            maxTsServerMemory = 4096,
            useSyntaxServer = "auto",
          },
          updateImportsOnFileMove = { enabled = "always" },
          suggest = {
            completeFunctionCalls = true,
          },
          inlayHints = {
            enumMemberValues = { enabled = true },
            functionLikeReturnTypes = { enabled = true },
            parameterNames = { enabled = "literals" },
            parameterTypes = { enabled = true },
            propertyDeclarationTypes = { enabled = true },
            variableTypes = { enabled = false },
          },
        },
      },
      keys = {
        {
          "gD",
          function()
            local params = vim.lsp.util.make_position_params(0, "utf-8")
            lsp.execute({
              command = "typescript.goToSourceDefinition",
              arguments = { params.textDocument.uri, params.position },
              open = true,
            })
          end,
          desc = "goto source definition",
        },
        {
          "gR",
          function()
            lsp.execute({
              command = "typescript.findAllFileReferences",
              arguments = { vim.uri_from_bufnr(0) },
              open = true,
            })
          end,
          desc = "file references",
        },
        {
          "<leader>co",
          lsp.action["source.organizeImports"],
          desc = "organize imports",
        },
        {
          "<leader>cM",
          lsp.action["source.addMissingImports.ts"],
          desc = "add missing imports",
        },
        {
          "<leader>cu",
          lsp.action["source.removeUnused.ts"],
          desc = "remove unused imports",
        },
        {
          "<leader>cD",
          lsp.action["source.fixAll.ts"],
          desc = "fix all diagnostics",
        },
        {
          "<leader>cV",
          function()
            lsp.execute({ command = "typescript.selectTypeScriptVersion" })
          end,
          desc = "select ts workspace version",
        },
      },
    },

    ["typescript-tools"] = {
      keys = {
        {
          "<leader>co",
          "<cmd>TSToolsOrganizeImports<cr>",
          desc = "organize imports",
        },
      },
    },
  },

  setup = {
    vtsls = function()
      -- Copy typescript settings to javascript so both share the same configuration.
      local spec = require("plugins.lsp.config")
      spec.servers["vtsls"].settings.javascript = vim.tbl_deep_extend(
        "force",
        {},
        spec.servers["vtsls"].settings.typescript,
        spec.servers["vtsls"].settings.javascript or {}
      )

      lsp.on_attach(function(client, _)
        client.commands["_typescript.moveToFileRefactoring"] = function(
          command,
          _
        )
          local arg0, arg1, arg2 = utils.unpack(command.arguments)

          ---@type string, string, lsp.Range
          local action, uri, range =
            tostring(arg0), tostring(arg1), {
              start = { line = arg2 and arg2.start_line or 0, character = arg2 and arg2.start_char or 0 },
              ["end"] = { line = arg2 and arg2.end_line or 0, character = arg2 and arg2.end_char or 0 },
            }

          local function move(new_file)
            client:request("workspace/executeCommand", {
              command = command.command,
              arguments = { action, uri, range, new_file },
            })
          end

          local file_name = vim.uri_to_fname(uri)
          client:request("workspace/executeCommand", {
            command = "typescript.tsserverRequest",
            arguments = {
              "getMoveToRefactoringFileSuggestions",
              {
                file = file_name,
                startLine = range.start.line + 1,
                startOffset = range.start.character + 1,
                endLine = range["end"].line + 1,
                endOffset = range["end"].character + 1,
              },
            },
          }, function(_, result)
            ---@type string[]
            local files = result.body.files
            table.insert(files, 1, "Enter new path...")
            vim.ui.select(files, {
              prompt = "Select move destination:",
              format_item = function(file)
                return vim.fn.fnamemodify(file, ":~:.")
              end,
            }, function(file)
              if file and file:find("^Enter new path") then
                vim.ui.input({
                  prompt = "Enter move destination:",
                  default = vim.fn.fnamemodify(file_name, ":h") .. "/",
                  completion = "file",
                }, function(new_file)
                  if type(new_file) == "string" then
                    move(new_file)
                  end
                end)
              elseif file then
                move(file)
              end
            end)
          end)
        end
      end, "vtsls")
    end,
  },
}
