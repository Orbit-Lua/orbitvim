describe("utils.sqlfluff", function()
  local test = require("tests.helpers")
  local sqlfluff = require("utils.sqlfluff")

  local function temp_dir(suffix)
    return test.temp_dir("sqlfluff-" .. (suffix or "case"))
  end

  local function write(path, content)
    test.write_file(path, content)
  end

  local function has_arg(args, value)
    return vim.tbl_contains(args, value)
  end

  after_each(function()
    test.cleanup_all()
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

    test.assert_path(config, sqlfluff.find_config(filename))
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

    test.assert_path(config, sqlfluff.find_config(filename))
    assert.is_false(has_arg(sqlfluff.format_args(filename), "--config"))
  end)

  it(
    "discovers supported config files by reading their SQLFluff section",
    function()
      local fixtures = {
        [".sqlfluff"] = "[sqlfluff]\ndialect = postgres\n",
        ["pep8.ini"] = "[sqlfluff:rules]\nmax_line_length = 88\n",
        ["pyproject.toml"] = '[tool.sqlfluff.core]\ndialect = "postgres"\n',
        ["setup.cfg"] = "[sqlfluff]\ndialect = postgres\n",
        ["tox.ini"] = "[sqlfluff:indentation]\nindent_unit = space\n",
      }
      local index = 0
      for name, content in pairs(fixtures) do
        index = index + 1
        local root = temp_dir("config-" .. index)
        local config = root .. "/" .. name
        local filename = root .. "/nested/query.sql"
        vim.fn.mkdir(root .. "/nested", "p")
        write(config, content)
        test.assert_path(config, sqlfluff.find_config(filename), name)
      end
    end
  )

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

  it(
    "keeps a positive bounded parse depth in the fallback SQLFluff config",
    function()
      local root = temp_dir()
      local config = root .. "/.sqlfluff"
      local filename = root .. "/query.sql"
      write(config, vim.fn.readfile(sqlfluff.fallback_config))

      test.assert_path(config, sqlfluff.find_config(filename))
      local depth
      for _, line in ipairs(vim.fn.readfile(sqlfluff.find_config(filename))) do
        depth = tonumber(line:match("^%s*max_parse_depth%s*=%s*(%d+)%s*$"))
          or depth
      end
      assert.is_true(depth ~= nil and depth > 0 and depth <= 512)
    end
  )

  it("uses the same project root for formatter and linter processes", function()
    local root = temp_dir()
    local filename = root .. "/queries/report.sql"
    vim.fn.mkdir(root .. "/.git", "p")
    vim.fn.mkdir(root .. "/queries", "p")

    test.assert_path(root, sqlfluff.cwd(filename))
  end)
end)
