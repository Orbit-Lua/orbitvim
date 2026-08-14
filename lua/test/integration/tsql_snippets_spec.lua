local test = require("test.helpers")
local luasnip_path = test.plugin_path("LuaSnip")
vim.opt.runtimepath:append(luasnip_path)

local snippets = dofile(vim.fn.getcwd() .. "/luasnippets/tsql.lua")

local function index_by_trigger()
  local indexed = {}

  for _, snippet in ipairs(snippets) do
    assert.is_nil(
      indexed[snippet.trigger],
      "duplicate trigger: " .. snippet.trigger
    )
    indexed[snippet.trigger] = snippet
  end

  return indexed
end

local function body(snippet)
  return table.concat(snippet:get_docstring(), "\n")
end

describe("T-SQL snippets", function()
  local indexed = index_by_trigger()

  it("provides the complete convention-based collection", function()
    for _, trigger in ipairs({
      "ctable",
      "idxinc",
      "cview",
      "cprocr",
      "cprocw",
      "citvf",
      "sel",
      "ijoin",
      "cte",
      "rowpart",
      "ins",
      "updo",
      "delo",
      "upsert",
      "temptable",
      "txn",
      "dynsql",
      "dynident",
      "grantobj",
      "utccol",
    }) do
      assert.is_not_nil(indexed[trigger], "missing trigger: " .. trigger)
    end
  end)

  it("uses unique non-empty triggers and names", function()
    for _, snippet in ipairs(snippets) do
      assert.is_true(
        type(snippet.trigger) == "string" and snippet.trigger ~= ""
      )
      assert.is_true(type(snippet.name) == "string" and snippet.name ~= "")
    end
  end)

  it("documents every trigger in the complete guide", function()
    local documentation = table.concat(
      vim.fn.readfile(vim.fn.getcwd() .. "/doc/tsql-snippets.md"),
      "\n"
    )

    for _, snippet in ipairs(snippets) do
      assert.is_truthy(
        documentation:find("`" .. snippet.trigger .. "`", 1, true),
        "undocumented trigger: " .. snippet.trigger
      )
    end
  end)

  it("follows programmable-object and transaction conventions", function()
    local read_procedure = body(indexed.cprocr)
    assert.is_truthy(read_procedure:find("CREATE OR ALTER PROCEDURE", 1, true))
    assert.is_truthy(read_procedure:find("SET NOCOUNT ON;", 1, true))

    local write_procedure = body(indexed.cprocw)
    assert.is_truthy(write_procedure:find("SET XACT_ABORT ON;", 1, true))
    assert.is_truthy(write_procedure:find("IF XACT_STATE() <> 0", 1, true))
    assert.is_truthy(write_procedure:find("ROLLBACK TRANSACTION;", 1, true))
    assert.is_truthy(write_procedure:find("THROW;", 1, true))
  end)

  it(
    "parameterizes dynamic values and validates dynamic identifiers",
    function()
      local dynamic_sql = body(indexed.dynsql)
      assert.is_truthy(dynamic_sql:find("EXEC sys.sp_executesql", 1, true))
      assert.is_truthy(dynamic_sql:find("@Status = @Status", 1, true))

      local dynamic_identifier = body(indexed.dynident)
      assert.is_truthy(dynamic_identifier:find("NOT IN", 1, true))
      assert.is_truthy(dynamic_identifier:find("QUOTENAME", 1, true))
    end
  )

  it("does not encode prohibited query and error anti-patterns", function()
    for _, snippet in ipairs(snippets) do
      local snippet_body = body(snippet)
      assert.is_nil(snippet_body:match("SELECT%s+%*"), snippet.trigger)
      assert.is_nil(snippet_body:find("RAISERROR", 1, true), snippet.trigger)
      assert.is_nil(snippet_body:find("EXEC (@Sql)", 1, true), snippet.trigger)
    end
  end)
end)
