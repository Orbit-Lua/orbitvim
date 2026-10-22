describe("TypeScript diagnostic publishing", function()
  it(
    "keeps matching messages at different locations while removing identical duplicates",
    function()
      local original = vim.lsp.diagnostic.on_publish_diagnostics
      local published
      vim.lsp.diagnostic.on_publish_diagnostics = function(_, result)
        published = result
      end
      local first = {
        source = "tsserver",
        message = "Cannot find name foo",
        severity = 1,
        range = {
          start = { line = 1, character = 0 },
          ["end"] = { line = 1, character = 3 },
        },
      }
      local second = vim.deepcopy(first)
      second.range.start.line, second.range["end"].line = 8, 8
      local unrelated = vim.deepcopy(first)
      unrelated.source = "eslint"
      local handler =
        require("config.lsp.typescript_tools").handlers["textDocument/publishDiagnostics"]
      local ok, err = pcall(
        handler,
        nil,
        { diagnostics = { first, vim.deepcopy(first), second, unrelated } },
        {}
      )
      vim.lsp.diagnostic.on_publish_diagnostics = original
      assert.is_true(ok, err)
      assert.same({ first, second }, published.diagnostics)
    end
  )
end)
