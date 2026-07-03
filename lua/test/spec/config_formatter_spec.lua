describe("config.formatter", function()
  local formatter = require("config.formatter")

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
end)
