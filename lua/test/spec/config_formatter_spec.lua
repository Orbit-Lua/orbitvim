describe("config.formatter", function()
  local formatter = require("config.formatter")

  it("only declares options supported by Conform defaults", function()
    assert.is_nil(formatter.default_format_opts.async)
    assert.same(5000, formatter.default_format_opts.timeout_ms)
  end)

  it("uses the project-local Prisma formatter on Unix", function()
    local fs = require("utils.fs")
    local os_utils = require("utils.os")
    local original_get_root = fs.get_root
    local original_is_win = os_utils.is_win

    fs.get_root = function()
      return "/tmp/project"
    end
    os_utils.is_win = function()
      return false
    end

    assert.equals(
      "/tmp/project/node_modules/.bin/prisma",
      formatter.formatters.prisma_fmt.command()
    )

    fs.get_root = original_get_root
    os_utils.is_win = original_is_win
  end)

  it("uses the project-local Prisma formatter on Windows", function()
    local fs = require("utils.fs")
    local os_utils = require("utils.os")
    local original_get_root = fs.get_root
    local original_is_win = os_utils.is_win

    fs.get_root = function()
      return "C:/project"
    end
    os_utils.is_win = function()
      return true
    end

    assert.equals(
      "C:/project/node_modules/.bin/prisma.CMD",
      formatter.formatters.prisma_fmt.command()
    )

    fs.get_root = original_get_root
    os_utils.is_win = original_is_win
  end)

  it("passes SQL buffer context to SQLFluff", function()
    local sqlfluff = require("utils.sqlfluff")
    local original_format_args = sqlfluff.format_args
    local original_cwd = sqlfluff.cwd
    local filename = "/tmp/project/query.sql"

    sqlfluff.format_args = function(path)
      assert.same(filename, path)
      return { "format", "--stdin-filename", path, "-" }
    end
    sqlfluff.cwd = function(path)
      assert.same(filename, path)
      return "/tmp/project"
    end

    assert.same(
      { "format", "--stdin-filename", filename, "-" },
      formatter.formatters.sqlfluff.args(nil, { filename = filename })
    )
    assert.same(
      "/tmp/project",
      formatter.formatters.sqlfluff.cwd(nil, { filename = filename })
    )

    sqlfluff.format_args = original_format_args
    sqlfluff.cwd = original_cwd
  end)
end)
