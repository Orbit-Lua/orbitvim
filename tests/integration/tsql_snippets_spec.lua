describe("T-SQL snippet expansions", function()
  local test = require("tests.helpers")
  local original_runtimepath, original_buffer, buffer, ls, snippets

  before_each(function()
    original_runtimepath = vim.o.runtimepath
    vim.opt.runtimepath:append(test.plugin_path("LuaSnip"))
    ls = require("luasnip")
    snippets = {}
    for _, snippet in ipairs(dofile("luasnippets/tsql.lua")) do
      assert.is_nil(snippets[snippet.trigger], "duplicate snippet trigger")
      snippets[snippet.trigger] = snippet
    end
    original_buffer = vim.api.nvim_get_current_buf()
    buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
  end)

  after_each(function()
    if buffer and vim.api.nvim_buf_is_valid(buffer) then
      ls.unlink_current()
      vim.api.nvim_set_current_buf(original_buffer)
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
    vim.o.runtimepath = original_runtimepath
  end)

  local function expand(trigger)
    ls.unlink_current()
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    ls.snip_expand(assert(snippets[trigger]):copy())
    return table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
  end

  it(
    "expands procedures with explicit queries and safe transactions",
    function()
      local read = expand("cprocr")
      assert.is_truthy(
        read:find("CREATE OR ALTER PROCEDURE dbo.GetEntity", 1, true)
      )
      assert.is_truthy(read:find("WHERE e.EntityId = @EntityId;", 1, true))
      local write = expand("cprocw")
      assert.is_truthy(write:find("SET XACT_ABORT ON;", 1, true))
      assert.is_truthy(write:find("IF XACT_STATE() <> 0", 1, true))
      assert.is_truthy(write:find("ROLLBACK TRANSACTION;", 1, true))
      assert.is_truthy(write:find("THROW;", 1, true))
      assert.is_true(ls.jumpable(1))
    end
  )

  it(
    "expands dynamic values as parameters and reuses whitelisted identifiers",
    function()
      local values = expand("dynsql")
      assert.is_truthy(values:find("EXEC sys.sp_executesql", 1, true))
      assert.is_truthy(values:find("@Status = @Status", 1, true))
      local identifier = expand("dynident")
      assert.is_truthy(identifier:find("IF @SortColumn NOT IN", 1, true))
      assert.is_truthy(identifier:find("QUOTENAME(@SortColumn)", 1, true))
    end
  )

  it(
    "expands every template without unsafe SQL or unresolved placeholders",
    function()
      for trigger in pairs(snippets) do
        local output = expand(trigger)
        assert.is_nil(output:match("SELECT%s+%*"), trigger)
        assert.is_nil(output:find("RAISERROR", 1, true), trigger)
        assert.is_nil(output:find("EXEC (@Sql)", 1, true), trigger)
        assert.is_nil(output:match("%${%d"), trigger)
      end
    end
  )
end)
