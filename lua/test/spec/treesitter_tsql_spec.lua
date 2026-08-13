describe("T-SQL highlighting", function()
  local config = require("config.treesitter").sql
  local treesitter = require("utils.treesitter")
  local buffers = {}

  local function buffer(lines, filetype)
    local buf = vim.api.nvim_create_buf(false, true)
    table.insert(buffers, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("filetype", filetype or "sql", { buf = buf })
    return buf
  end

  local function syntax_name(buf, row, column)
    return vim.api.nvim_buf_call(buf, function()
      local id = vim.fn.synID(row, column, true)
      return vim.fn.synIDattr(id, "name")
    end)
  end

  local function captures(source)
    treesitter.setup()
    local parser = assert(vim.treesitter.get_string_parser(source, "sql"))
    local root = assert(parser:parse()[1]):root()
    local query = assert(vim.treesitter.query.get("sql", "highlights"))
    local result = {}

    for id, node in query:iter_captures(root, source, 0, -1) do
      local text = vim.treesitter.get_node_text(node, source)
      result[text:upper()] = query.captures[id]
    end

    return result
  end

  before_each(function()
    config.dialect = "tsql"
    config.markdown_fenced_fallback = true
    config.syntax_fallback = true
    vim.g.markdown_fenced_languages = nil
    vim.g.sql_type_default = nil
  end)

  after_each(function()
    for _, buf in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    buffers = {}
    vim.g.markdown_fenced_languages = nil
    vim.g.sql_type_default = nil
  end)

  it("extends the SQL query with T-SQL semantic corrections", function()
    local top = captures("SELECT TOP (10) * FROM dbo.Users;")
    local nocount = captures("SET NOCOUNT ON;")
    local xact_abort = captures("SET XACT_ABORT ON;")
    local disable = captures("ALTER INDEX IX_Users ON dbo.Users DISABLE;")

    assert.equals("keyword", top.TOP)
    assert.equals("keyword", nocount.NOCOUNT)
    assert.equals("keyword", xact_abort.XACT_ABORT)
    assert.equals("keyword", disable.DISABLE)
  end)

  it("selects the configured dialect and enables its fallback", function()
    local buf = buffer({ "BEGIN TRY", "  SELECT @@ROWCOUNT;", "END TRY" })

    treesitter.start(buf)

    assert.equals("tsql", vim.b[buf].sql_type_override)
    assert.equals("tsql", vim.b[buf].current_syntax)
  end)

  it("preserves an explicit buffer dialect", function()
    local buf = buffer({ "SELECT 1;" })
    vim.b[buf].sql_type_override = "sqloracle"

    treesitter.start(buf)

    assert.equals("sqloracle", vim.b[buf].sql_type_override)
    assert.is_not_nil(vim.b[buf].current_syntax)
  end)

  it("preserves the global SQL dialect default", function()
    vim.g.sql_type_default = "sqloracle"
    local buf = buffer({ "SELECT 1;" })

    treesitter.start(buf)

    assert.is_nil(vim.b[buf].sql_type_override)
    assert.is_not_nil(vim.b[buf].current_syntax)
  end)

  it("can disable the legacy syntax fallback", function()
    config.syntax_fallback = false
    local buf = buffer({ "SELECT 1;" })

    treesitter.start(buf)

    assert.is_nil(vim.b[buf].sql_type_override)
    assert.is_nil(vim.b[buf].current_syntax)
  end)

  it("does not apply the SQL dialect to other filetypes", function()
    local buf = buffer({ "local value = 1" }, "lua")

    treesitter.start(buf)

    assert.is_nil(vim.b[buf].sql_type_override)
  end)

  it("loads the T-SQL fallback inside Markdown SQL fences", function()
    local buf = buffer({
      "# Example",
      "",
      "```sql",
      "GO 2",
      "BEGIN TRY",
      "  SELECT @@ROWCOUNT, @UserId FROM [dbo].[Users];",
      "END TRY",
      "```",
    }, "markdown")

    treesitter.start(buf)

    assert.same({ "sql=tsql" }, vim.g.markdown_fenced_languages)
    assert.equals("markdown", vim.b[buf].current_syntax)
    assert.equals("tsqlBatchSeparator", syntax_name(buf, 4, 1))
    assert.equals("tsqlBatchCount", syntax_name(buf, 4, 4))
    assert.equals("tsqlKeyword", syntax_name(buf, 5, 7))
    assert.equals("tsqlSystemVariable", syntax_name(buf, 6, 10))
    assert.equals("tsqlVariable", syntax_name(buf, 6, 22))
    assert.equals("tsqlBracketIdentifier", syntax_name(buf, 6, 35))
  end)

  it(
    "restores the Markdown fallback after a later Tree-sitter start",
    function()
      local buf = buffer({
        "```sql",
        "BEGIN TRY",
        "```",
      }, "markdown")

      treesitter.start(buf)
      vim.treesitter.start(buf)

      assert.is_true(vim.wait(100, function()
        return vim.b[buf].current_syntax == "markdown"
      end))
      assert.equals("tsqlKeyword", syntax_name(buf, 2, 7))
    end
  )

  it("preserves an explicit Markdown SQL fence dialect", function()
    vim.g.markdown_fenced_languages = { "python", "sql", "sql=sqloracle" }
    local buf = buffer({ "```sql", "SELECT 1;", "```" }, "markdown")

    treesitter.start(buf)

    assert.same({ "python", "sql=sqloracle" }, vim.g.markdown_fenced_languages)
  end)

  it("can disable the Markdown SQL fence fallback", function()
    config.markdown_fenced_fallback = false
    local buf = buffer({ "```sql", "TRY", "```" }, "markdown")

    treesitter.start(buf)

    assert.is_nil(vim.g.markdown_fenced_languages)
    assert.is_nil(vim.b[buf].current_syntax)
  end)

  it("contains Markdown fallback matches within SQL fences", function()
    local buf = buffer({
      "TRY @Prose is not SQL.",
      "",
      "```text",
      "TRY @TextFence",
      "```",
      "",
      "```sql",
      "BEGIN TRY",
      "```",
    }, "markdown")

    treesitter.start(buf)

    assert.is_nil(syntax_name(buf, 1, 1):match("^tsql"))
    assert.is_nil(syntax_name(buf, 4, 1):match("^tsql"))
    assert.equals("tsqlKeyword", syntax_name(buf, 8, 7))
  end)

  it("highlights parser edge cases with focused syntax groups", function()
    local buf = buffer({
      "GO 2",
      "BEGIN TRY",
      "  SELECT @@ROWCOUNT, @UserId FROM [dbo].[Users];",
      "END TRY",
    })

    treesitter.start(buf)

    assert.equals("tsqlBatchSeparator", syntax_name(buf, 1, 1))
    assert.equals("tsqlBatchCount", syntax_name(buf, 1, 4))
    assert.equals("tsqlKeyword", syntax_name(buf, 2, 7))
    assert.equals("tsqlSystemVariable", syntax_name(buf, 3, 10))
    assert.equals("tsqlVariable", syntax_name(buf, 3, 22))
    assert.equals("tsqlBracketIdentifier", syntax_name(buf, 3, 35))
  end)

  it("does not match fallback keywords inside strings or comments", function()
    local buf = buffer({
      "SELECT 'TRY @@ROWCOUNT';",
      "-- CATCH @UserId",
      "SELECT GO FROM dbo.Batches;",
    })

    treesitter.start(buf)

    assert.equals("tsqlString", syntax_name(buf, 1, 9))
    assert.equals("tsqlLineComment", syntax_name(buf, 2, 4))
    assert.equals("", syntax_name(buf, 3, 8))
  end)
end)
