local fs = require("utils.fs")
local sqlfluff_util = require("utils.sqlfluff")

---@class LinterExtend
---@field condition? boolean

---@alias Linter lint.Linter | LinterExtend | fun(): lint.Linter | LinterExtend

---@module "lint"
---@class Linter.Opts
---@field events LazyEvent
---@field linters_by_ft table
---@field linters Linter

---@type Linter.Opts
return {
  events = { "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" },
  linters_by_ft = require("config.packages").linters_by_ft,

  linters = {
    luacheck = {
      cmd = "luacheck",
      stdin = true,
      args = {
        "--globals",
        "vim",
        "--formatter",
        "plain",
        "--codes",
        "--ranges",
        "-",
      },
    },

    sqlfluff = function()
      local linter = vim.deepcopy(require("lint.linters.sqlfluff"))
      local filename = vim.api.nvim_buf_get_name(0)
      linter.args = sqlfluff_util.lint_args(filename)
      linter.cwd = sqlfluff_util.cwd(filename)
      linter.env = { PYTHONUTF8 = "1" }
      return linter
    end,

    ["markdownlint-cli2"] = {
      cmd = "markdownlint-cli2",
      stdin = true,
      args = {
        "--config",
        fs.config_path .. "/lua/config/linter/template/.markdownlint.yaml",
        "-",
      },
      ignore_exitcode = true,
      stream = "stderr",
      parser = require("lint.parser").from_errorformat(
        "stdin:%l:%c %m,stdin:%l %m",
        {
          source = "markdownlint",
          severity = vim.diagnostic.severity.WARN,
        }
      ),
    },
  },
}
