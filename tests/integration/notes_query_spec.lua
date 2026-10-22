describe("notes Markdown highlights", function()
  local original_obsidian

  before_each(function()
    original_obsidian = package.loaded.obsidian
    package.loaded.obsidian = { setup = function() end }
  end)

  after_each(function()
    package.loaded.obsidian = original_obsidian
    vim.treesitter.query.set("markdown", "highlights", nil)
  end)

  it(
    "keeps headings highlighted and code fences visible with conceal enabled",
    function()
      require("runtime.notes").setup({})
      local source = "# Title\n\n```sql\nSELECT 1;\n```\n"
      local parser =
        assert(vim.treesitter.get_string_parser(source, "markdown"))
      local root = assert(parser:parse()[1]):root()
      local query = assert(vim.treesitter.query.get("markdown", "highlights"))
      local heading, fence, language = false, false, false
      for id, node, metadata in query:iter_captures(root, source, 0, -1) do
        local capture = query.captures[id]
        local kind = node:type()
        heading = heading or capture == "markup.heading.1"
        fence = fence or kind == "fenced_code_block_delimiter"
        language = language or kind == "language"
        if kind == "fenced_code_block_delimiter" or kind == "language" then
          assert.is_nil(metadata.conceal)
          assert.is_nil(metadata.conceal_lines)
          assert.is_nil((metadata[id] or {}).conceal)
          assert.is_nil((metadata[id] or {}).conceal_lines)
        end
      end
      assert.is_true(heading)
      assert.is_true(fence)
      assert.is_true(language)
    end
  )
end)
