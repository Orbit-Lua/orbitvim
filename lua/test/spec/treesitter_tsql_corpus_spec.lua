describe("T-SQL conventions highlighting corpus", function()
  local treesitter = require("utils.treesitter")
  local config = require("config.treesitter").sql
  local lines
  local buf

  local function syntax_name(row, column)
    return vim.api.nvim_buf_call(buf, function()
      local id = vim.fn.synID(row, column, true)
      return vim.fn.synIDattr(id, "name")
    end)
  end

  local function sql_fences()
    local fences = {}
    local current

    for row, line in ipairs(lines) do
      if not current and line:match("^```sql%s*$") then
        current = { opening = row, start_row = row }
      elseif current and line:match("^```%s*$") then
        current.end_row = row - 1
        table.insert(fences, current)
        current = nil
      end
    end

    assert.is_nil(current, "unterminated SQL fence in conventions document")
    return fences
  end

  local function sql_capture_ranges(parser)
    local query = assert(vim.treesitter.query.get("sql", "highlights"))
    local by_row = {}

    parser:for_each_tree(function(tree)
      for _, node in query:iter_captures(tree:root(), buf, 0, -1) do
        local start_row, start_col, end_row, end_col = node:range()
        for row = start_row, end_row do
          by_row[row] = by_row[row] or {}
          table.insert(by_row[row], {
            row == start_row and start_col or 0,
            row == end_row and end_col or math.huge,
          })
        end
      end
    end)

    return by_row
  end

  local function is_captured(ranges, row, column)
    for _, range in ipairs(ranges[row] or {}) do
      if column >= range[1] and column < range[2] then
        return true
      end
    end
    return false
  end

  before_each(function()
    config.dialect = "tsql"
    config.markdown_fenced_fallback = true
    config.syntax_fallback = true
    vim.g.markdown_fenced_languages = nil

    lines = vim.fn.readfile("doc/tsql-conventions.md")
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
    treesitter.setup()
    treesitter.start(buf)
  end)

  after_each(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.g.markdown_fenced_languages = nil
  end)

  it("injects SQL into every documented SQL fence", function()
    local fences = sql_fences()
    local markdown = assert(vim.treesitter.get_parser(buf, "markdown"))
    markdown:parse(true)
    local sql = assert(markdown:children().sql)
    local tree_ranges = {}

    sql:for_each_tree(function(tree)
      local start_row, _, end_row = tree:root():range()
      table.insert(tree_ranges, { start_row, end_row })
    end)

    assert.is_true(#fences > 0)
    for _, fence in ipairs(fences) do
      local injected = false
      for _, range in ipairs(tree_ranges) do
        if range[1] < fence.end_row and range[2] >= fence.start_row then
          injected = true
          break
        end
      end
      assert.is_true(
        injected,
        "SQL fence at line " .. fence.opening .. " was not injected"
      )
    end
  end)

  it("highlights every uppercase lexeme in the SQL corpus", function()
    local markdown = assert(vim.treesitter.get_parser(buf, "markdown"))
    markdown:parse(true)
    local ranges = sql_capture_ranges(assert(markdown:children().sql))
    local in_sql = false
    local missing = {}

    for row, line in ipairs(lines) do
      if line:match("^```sql%s*$") then
        in_sql = true
      elseif in_sql and line:match("^```%s*$") then
        in_sql = false
      elseif in_sql then
        local start = 1
        while true do
          local from, to = line:find("%f[%a_][A-Z][A-Z_0-9]*%f[^%w_]", start)
          if not from then
            break
          end

          local syntax = syntax_name(row, from)
          if
            not is_captured(ranges, row - 1, from - 1)
            and not syntax:match("^tsql")
          then
            table.insert(
              missing,
              string.format("%d:%d %s", row, from, line:sub(from, to))
            )
          end
          start = to + 1
        end
      end
    end

    assert.same({}, missing)
  end)

  it("exercises every fallback category in the corpus", function()
    local groups = {}
    local patterns = {
      "^%s*%f[%a]GO%f[%A]",
      "@@[A-Za-z_][A-Za-z_0-9]*",
      "@%a[A-Za-z_0-9]*",
      "%[[^]]+%]",
      "%f[%a]N'",
      "%f[%a]TRY%f[%A]",
      "%f[%a]BIGINT%f[%A]",
      "%f[%a]SYSUTCDATETIME%f[%A]",
    }
    local in_sql = false

    for row, line in ipairs(lines) do
      if line:match("^```sql%s*$") then
        in_sql = true
      elseif in_sql and line:match("^```%s*$") then
        in_sql = false
      elseif in_sql then
        for _, pattern in ipairs(patterns) do
          local column = line:find(pattern)
          if column then
            local name = syntax_name(row, column)
            if name:match("^tsql") then
              groups[name] = true
            end
          end
        end
      end
    end

    for _, name in ipairs({
      "tsqlBatchSeparator",
      "tsqlBracketIdentifier",
      "tsqlBuiltinFunction",
      "tsqlKeyword",
      "tsqlStringPrefix",
      "tsqlSystemVariable",
      "tsqlType",
      "tsqlVariable",
    }) do
      assert.is_true(groups[name], name .. " is not exercised by the corpus")
    end
  end)
end)
