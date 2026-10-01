describe("config.formatter", function()
  local formatter = require("config.formatter")
  local fs = require("utils.fs")
  local os_utils = require("utils.os")
  local sqlfluff = require("utils.sqlfluff")
  local originals

  before_each(function()
    originals = {
      get_root = fs.get_root,
      is_win = os_utils.is_win,
      format_args = sqlfluff.format_args,
      cwd = sqlfluff.cwd,
    }
  end)

  after_each(function()
    fs.get_root = originals.get_root
    os_utils.is_win = originals.is_win
    sqlfluff.format_args = originals.format_args
    sqlfluff.cwd = originals.cwd
  end)

  it("uses the project-local Prisma formatter on Unix", function()
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
  end)

  it("uses the project-local Prisma formatter on Windows", function()
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
  end)

  it("passes SQL buffer context to SQLFluff", function()
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

    assert.same("1", formatter.formatters.sqlfluff.env.PYTHONUTF8)
  end)
end)
