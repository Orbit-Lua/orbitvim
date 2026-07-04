local fs = require("utils.fs")
local os_util = require("utils.os")

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
  },

  -- refer to: https://github.com/mfussenegger/nvim-lint#custom-linters
  linters = {
    -- Mason-installed luacheck (1.1.0) crashes on Lua 5.5 because Lua 5.5 makes
    -- for-loop variables <const>. Point directly at the luarocks-installed 1.2.0
    -- binary (lua5.4) which is already on PATH but shadowed by Mason's bin dir.
    luacheck = {
      cmd = os_util.is_linux()
          and (os.getenv("HOME") or "") .. "/.luarocks/bin/luacheck"
        or "luacheck.bat",
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

    sqlfluff = {
      cmd = "sqlfluff",
      args = (function()
        for _, file in ipairs(fs.sqlfluff_pattern) do
          local path = fs.get_root() .. "/" .. file
          if vim.uv.fs_stat(path) ~= nil then
            return { "lint", "--format=json" }
          end
        end

        local config_path = fs.config_path
          .. "/lua/config/db/template/sqlfluff.cfg"
        return { "lint", "--format=json", "--config", config_path }
      end)(),
    },

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
        -- efm
        "stdin:%l:%c %m,stdin:%l %m",
        {
          source = "markdownlint",
          severity = vim.diagnostic.severity.WARN,
        }
      ),
    },
  },
}
