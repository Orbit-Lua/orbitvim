describe("C# Treesitter injections", function()
  local config = require("config.treesitter").sql_injections

  before_each(function()
    config.comment = true
    config.auto = true
    require("utils.treesitter").setup()
  end)

  local function sql_injections(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local parser = assert(vim.treesitter.get_parser(buf, "c_sharp"))
    parser:parse(true)
    local sql_parser = parser:children().sql
    local has_sql_parser = sql_parser ~= nil

    vim.api.nvim_buf_delete(buf, { force = true })
    return has_sql_parser
  end

  local function sql_trees(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local parser = assert(vim.treesitter.get_parser(buf, "c_sharp"))
    parser:parse(true)
    local sql_parser = assert(parser:children().sql)
    local tree_count = 0
    local has_errors = false
    local range_count = 0

    sql_parser:for_each_tree(function(tree)
      tree_count = tree_count + 1
      has_errors = has_errors or tree:root():has_error()
    end)
    for _, ranges in pairs(sql_parser:included_regions()) do
      range_count = range_count + #ranges
    end

    vim.api.nvim_buf_delete(buf, { force = true })
    return tree_count, has_errors, range_count
  end

  it("injects SQL after a language marker", function()
    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      "    // language=sql",
      '    var query = "SELECT * FROM users";',
      "  }",
      "}",
    })

    assert.is_true(has_sql_parser)
  end)

  it("supports raw SQL strings", function()
    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      "    // LANGUAGE = SQL",
      '    var query = """',
      "      SELECT * FROM users",
      '      """;',
      "  }",
      "}",
    })

    assert.is_true(has_sql_parser)
  end)

  it("injects verbatim SQL strings after a language marker", function()
    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      "    // language=sql",
      '    string sqlstr = @"select PID',
      "                      , Title",
      "                      from vd_PostList",
      '                      order by AnnounceDate desc";',
      "  }",
      "}",
    })

    assert.is_true(has_sql_parser)
  end)

  it("injects SQL into marked field declarations", function()
    local tree_count, has_errors = sql_trees({
      "class Queries {",
      "  // language=sql",
      '  private const string Query = "SELECT * FROM users";',
      "}",
    })

    assert.are.equal(1, tree_count)
    assert.is_false(has_errors)
  end)

  it("does not duplicate marked SQL-named field declarations", function()
    local tree_count, has_errors = sql_trees({
      "class Queries {",
      "  // language=sql",
      '  private const string SqlQuery = "SELECT * FROM users";',
      "}",
    })

    assert.are.equal(1, tree_count)
    assert.is_false(has_errors)
  end)

  it("automatically injects strings assigned to SQL-named variables", function()
    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      '    string sqlstr = @"SELECT * FROM users";',
      "  }",
      "}",
    })

    assert.is_true(has_sql_parser)
  end)

  it("skips escaped regular strings during automatic injection", function()
    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      '    var sqlQuery = "SELECT *\\nFROM users";',
      "  }",
      "}",
    })

    assert.is_false(has_sql_parser)
  end)

  it("skips escaped regular strings after a language marker", function()
    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      "    // language=sql",
      '    var query = "SELECT *\\nFROM users";',
      "  }",
      "}",
    })

    assert.is_false(has_sql_parser)
  end)

  it("skips escaped interpolated strings", function()
    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      '    var sqlQuery = $"SELECT *\\nFROM {table}";',
      "  }",
      "}",
    })

    assert.is_false(has_sql_parser)
  end)

  it("skips verbatim strings with doubled quotes", function()
    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      '    var sqlQuery = @"SELECT * FROM ""users""";',
      "  }",
      "}",
    })

    assert.is_false(has_sql_parser)
  end)

  it("supports camel-case and underscore SQL variable names", function()
    local tree_count, has_errors = sql_trees({
      "class Queries {",
      "  void Run() {",
      '    var sqlUsers = "SELECT * FROM users";',
      '    var sql_posts = "SELECT * FROM posts";',
      "  }",
      "}",
    })

    assert.are.equal(2, tree_count)
    assert.is_false(has_errors)
  end)

  it(
    "automatically injects later assignments to SQL-named variables",
    function()
      local has_sql_parser = sql_injections({
        "class Queries {",
        "  void Run() {",
        "    string sqlstr;",
        '    sqlstr = "SELECT * FROM users";',
        "  }",
        "}",
      })

      assert.is_true(has_sql_parser)
    end
  )

  it("injects marked assignments regardless of the variable name", function()
    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      "    string query;",
      "    // language=sql",
      '    query = "SELECT * FROM users";',
      "  }",
      "}",
    })

    assert.is_true(has_sql_parser)
  end)

  it("automatically injects member assignments", function()
    local has_sql_parser = sql_injections({
      "class Queries {",
      "  string sqlstr;",
      "  void Run() {",
      '    this.sqlstr = "SELECT * FROM users";',
      "  }",
      "}",
    })

    assert.is_true(has_sql_parser)
  end)

  it("does not automatically inject compound assignment fragments", function()
    local tree_count, has_errors = sql_trees({
      "class Queries {",
      "  void Run() {",
      '    string sqlQuery = "SELECT * FROM users";',
      '    sqlQuery += " WHERE id = 1";',
      "  }",
      "}",
    })

    assert.are.equal(1, tree_count)
    assert.is_false(has_errors)
  end)

  it("parses interpolated SQL as one injection", function()
    local tree_count, has_errors, range_count = sql_trees({
      "class Queries {",
      "  void Run() {",
      '    var sqlQuery = $"SELECT * FROM {table} WHERE id = {id}";',
      "  }",
      "}",
    })

    assert.are.equal(1, tree_count)
    assert.is_false(has_errors)
    assert.are.equal(4, range_count)
  end)

  it("includes children of complex interpolation expressions", function()
    local tree_count, has_errors, range_count = sql_trees({
      "class Queries {",
      "  void Run() {",
      '    var sqlQuery = $"SELECT * FROM {schema.Table} WHERE id = {request.Id}";',
      "  }",
      "}",
    })

    assert.are.equal(1, tree_count)
    assert.is_false(has_errors)
    assert.are.equal(4, range_count)
  end)

  it("does not duplicate marked SQL-named assignments", function()
    local tree_count, has_errors = sql_trees({
      "class Queries {",
      "  void Run() {",
      "    string sqlstr;",
      "    // language=sql",
      '    sqlstr = "SELECT * FROM users";',
      "  }",
      "}",
    })

    assert.are.equal(1, tree_count)
    assert.is_false(has_errors)
  end)

  it("parses separate SQL variables as independent injections", function()
    local tree_count, has_errors = sql_trees({
      "class Queries {",
      "  void Run() {",
      '    var sqlUsers = "SELECT * FROM users";',
      '    var sqlPosts = "SELECT * FROM posts";',
      "  }",
      "}",
    })

    assert.are.equal(2, tree_count)
    assert.is_false(has_errors)
  end)

  it("does not inject unmarked strings", function()
    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      '    var query = "SELECT * FROM users";',
      "  }",
      "}",
    })

    assert.is_false(has_sql_parser)
  end)

  it("can disable comment-style injections", function()
    config.comment = false

    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      "    // language=sql",
      '    var query = "SELECT * FROM users";',
      "  }",
      "}",
    })

    assert.is_false(has_sql_parser)
  end)

  it("keeps automatic injection when comment markers are disabled", function()
    config.comment = false

    local tree_count, has_errors = sql_trees({
      "class Queries {",
      "  void Run() {",
      "    string sqlstr;",
      "    // language=sql",
      '    sqlstr = "SELECT * FROM users";',
      "  }",
      "}",
    })

    assert.are.equal(1, tree_count)
    assert.is_false(has_errors)
  end)

  it("can disable automatic SQL variable injections", function()
    config.auto = false

    local has_sql_parser = sql_injections({
      "class Queries {",
      "  void Run() {",
      '    var sqlQuery = "SELECT * FROM users";',
      "  }",
      "}",
    })

    assert.is_false(has_sql_parser)
  end)
end)
