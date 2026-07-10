describe("utils.sqlfluff", function()
  local sqlfluff = require("utils.sqlfluff")
  local temp_dirs = {}

  local function temp_dir()
    local path = vim.fn.tempname()
    vim.fn.mkdir(path, "p")
    table.insert(temp_dirs, path)
    return path
  end

  local function write(path, content)
    local file = assert(io.open(path, "w"))
    file:write(content)
    file:close()
  end

  local function has_arg(args, value)
    return vim.tbl_contains(args, value)
  end

  after_each(function()
    for _, path in ipairs(temp_dirs) do
      vim.fn.delete(path, "rf")
    end
    temp_dirs = {}
  end)

  it(
    "uses the fallback config when a project has no SQLFluff config",
    function()
      local filename = temp_dir() .. "/query.sql"
      local args = sqlfluff.format_args(filename)

      assert.same("format", args[1])
      assert.is_true(has_arg(args, "--stdin-filename"))
      assert.is_true(has_arg(args, filename))
      assert.is_true(has_arg(args, "--config"))
      assert.is_true(has_arg(args, sqlfluff.fallback_config))
      assert.same("-", args[#args])
    end
  )

  it("discovers a project config from a nested SQL file", function()
    local root = temp_dir()
    local config = root .. "/.sqlfluff"
    local filename = root .. "/queries/report.sql"
    vim.fn.mkdir(root .. "/queries", "p")
    write(config, "[sqlfluff]\ndialect = postgres\n")

    assert.same(config, sqlfluff.find_config(filename))
    assert.is_false(has_arg(sqlfluff.format_args(filename), "--config"))
    assert.is_false(has_arg(sqlfluff.lint_args(filename), "--config"))
  end)

  it("ignores config filenames without SQLFluff sections", function()
    local root = temp_dir()
    local filename = root .. "/query.sql"
    write(root .. "/pyproject.toml", "[tool.black]\nline-length = 88\n")
    write(root .. "/setup.cfg", "[flake8]\nmax-line-length = 88\n")

    assert.is_nil(sqlfluff.find_config(filename))
    assert.is_true(
      has_arg(sqlfluff.format_args(filename), sqlfluff.fallback_config)
    )
  end)

  it("recognizes SQLFluff sections in pyproject.toml", function()
    local root = temp_dir()
    local config = root .. "/pyproject.toml"
    local filename = root .. "/query.sql"
    write(config, '[tool.sqlfluff.core]\ndialect = "postgres"\n')

    assert.same(config, sqlfluff.find_config(filename))
    assert.is_false(has_arg(sqlfluff.format_args(filename), "--config"))
  end)

  it("recognizes every supported SQLFluff config filename", function()
    local fs = require("utils.fs")
    for _, name in ipairs({
      ".sqlfluff",
      "pep8.ini",
      "pyproject.toml",
      "setup.cfg",
      "tox.ini",
    }) do
      assert.is_true(vim.tbl_contains(fs.sqlfluff_pattern, name), name)
    end
  end)

  it("builds matching formatter and linter file context", function()
    local filename = temp_dir() .. "/query.sql"
    local format_args = sqlfluff.format_args(filename)
    local lint_args = sqlfluff.lint_args(filename)

    assert.same("format", format_args[1])
    assert.same("lint", lint_args[1])
    assert.is_true(has_arg(lint_args, "--format=json"))
    assert.is_true(has_arg(format_args, filename))
    assert.is_true(has_arg(lint_args, filename))
    assert.is_true(has_arg(format_args, sqlfluff.fallback_config))
    assert.is_true(has_arg(lint_args, sqlfluff.fallback_config))
  end)

  it("keeps a bounded parse depth for complex T-SQL", function()
    local lines = vim.fn.readfile(sqlfluff.fallback_config)
    assert.is_true(vim.tbl_contains(lines, "max_parse_depth = 512"))
    assert.is_false(vim.tbl_contains(lines, "max_parse_depth = 0"))
  end)

  it("uses the same project root for formatter and linter processes", function()
    local root = temp_dir()
    local filename = root .. "/queries/report.sql"
    vim.fn.mkdir(root .. "/.git", "p")
    vim.fn.mkdir(root .. "/queries", "p")

    assert.same(root, sqlfluff.cwd(filename))
  end)

  it("honors T-SQL and PostgreSQL first-line dialect directives", function()
    if vim.fn.executable("sqlfluff") ~= 1 then
      pending("sqlfluff is not installed")
      return
    end

    local root = temp_dir()
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
