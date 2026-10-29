describe("SQLFluff executable", function()
  local test = require("tests.helpers")
  local sqlfluff = require("features.sql.runtime")

  before_each(function()
    assert.equals(
      1,
      vim.fn.executable("sqlfluff"),
      "sqlfluff is required for the integration suite"
    )
  end)

  after_each(function()
    test.cleanup_all()
  end)

  it("honors T-SQL and PostgreSQL first-line dialect directives", function()
    local root = test.temp_dir("sqlfluff-executable")
    local filename = root .. "/query.sql"
    local command = { "sqlfluff" }
    vim.list_extend(command, sqlfluff.format_args(filename))

    local tsql = vim
      .system(command, {
        text = true,
        stdin = "-- sqlfluff:dialect:tsql\nselect top (1) [UserID] from dbo.[Users];\n",
      })
      :wait()
    assert.same(0, tsql.code, tsql.stderr)
    assert.is_truthy(tsql.stdout:find("SELECT TOP %(1%) %[UserID%]"))
    assert.is_truthy(tsql.stdout:find("dbo%.%[Users%]"))

    local postgres = vim
      .system(command, {
        text = true,
        stdin = "-- sqlfluff:dialect:postgres\nselect payload::jsonb from events;\n",
      })
      :wait()
    assert.same(0, postgres.code, postgres.stderr)
    assert.is_truthy(postgres.stdout:find("SELECT payload::JSONB"))
    assert.is_truthy(postgres.stdout:find("FROM events"))
  end)

  it("formats a depth-20 expression with the fallback template", function()
    local root = test.temp_dir("sqlfluff-parse-depth")
    local filename = root .. "/query.sql"
    local command = { "sqlfluff" }
    vim.list_extend(command, sqlfluff.format_args(filename))

    -- This depth exceeds SQLFluff's default parser limit.
    local query = "select "
      .. string.rep("(", 20)
      .. "1 + 2"
      .. string.rep(")", 20)
      .. " as NestedValue;\n"
    local result =
      vim.system(command, { text = true, cwd = root, stdin = query }):wait()

    assert.same(0, result.code, result.stderr .. result.stdout)
    assert.is_truthy(result.stdout:find("^SELECT%s"))
  end)
end)
