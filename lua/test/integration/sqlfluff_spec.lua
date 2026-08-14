describe("SQLFluff executable", function()
  local test = require("test.helpers")
  local sqlfluff = require("utils.sqlfluff")

  after_each(function()
    test.cleanup_all()
  end)

  it("honors T-SQL and PostgreSQL first-line dialect directives", function()
    assert.equals(
      1,
      vim.fn.executable("sqlfluff"),
      "sqlfluff is required for the integration suite"
    )

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
end)
