local fs = require("utils.fs")
local os_utils = require("utils.os")
local sqlfluff_util = require("utils.sqlfluff")

-- Mason's luacheck 1.1.0 fails under Lua 5.5, whose for-loop variables are
-- <const>. Prefer a LuaRocks or standalone 1.2.0+ install even when an old
-- Mason package still shadows it on PATH.
local function luacheck_command()
  return os_utils.find_executable("luacheck", {
    exclude = vim.fn.stdpath("data") .. "/mason/bin",
  }) or "luacheck"
end

-- Built on first use so loading this config does not load nvim-lint.
local markdownlint_parse
local function markdownlint_parser(...)
  markdownlint_parse = markdownlint_parse
    or require("lint.parser").from_errorformat("stdin:%l:%c %m,stdin:%l %m", {
      source = "markdownlint",
      severity = vim.diagnostic.severity.WARN,
    })
  return markdownlint_parse(...)
end

---@class LinterExtend
---@field condition? boolean

---@alias Linter lint.Linter | LinterExtend | fun(): lint.Linter | LinterExtend

---@module "lint"
---@class Linter.Opts
---@field events LazyEvent
---@field skip_while_editing string[] linters that TextChanged alone does not run
---@field linters_by_ft table
---@field linters Linter

---@type Linter.Opts
return {
  events = { "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" },

  -- SQLFluff takes seconds to start; linting after every pause in typing
  -- would stack processes, and Windows cancels only their cmd.exe wrappers.
  skip_while_editing = { "sqlfluff" },

  -- available linters: https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#available-linters
  linters_by_ft = {
    -- ['*'] = { 'global linter' },
    -- ['_'] = { 'fallback linter' },
    -- ["*"] = { "typos" },

    dockerfile = { "hadolint" },
    markdown = { "markdownlint-cli2" },
    lua = { "luacheck" },

    typescript = { "eslint_d" },
    javascript = { "eslint_d" },

    typescriptreact = { "eslint_d" },
    javascriptreact = { "eslint_d" },
    jsx = { "eslint_d" },

    sql = { "sqlfluff" },
    mysql = { "sqlfluff" },
    plsql = { "sqlfluff" },
  },

  -- refer to: https://github.com/mfussenegger/nvim-lint#custom-linters
  linters = {
    luacheck = {
      cmd = luacheck_command(),
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
      parser = markdownlint_parser,
    },
  },
}
