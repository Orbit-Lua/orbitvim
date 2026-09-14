local fs = require("utils.fs")
local os_utils = require("utils.os")
local sqlfluff = require("utils.sqlfluff")

return {
  default_format_opts = {
    timeout_ms = 5000,
    quiet = false,
    lsp_format = "fallback",
  },

  formatters = {
    ["markdown-toc"] = {
      condition = function(_, ctx)
        for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
          if line:find("<!%-%- toc %-%->") then
            return true
          end
        end
      end,
    },
    ["markdownlint-cli2"] = {
      condition = function(_, ctx)
        local diagnostics = vim.tbl_filter(function(diagnostic)
          return diagnostic.source == "markdownlint"
        end, vim.diagnostic.get(ctx.buf))
        return #diagnostics > 0
      end,
    },
    sqlfluff = {
      command = "sqlfluff",
      env = { PYTHONUTF8 = "1" },
      args = function(_, ctx)
        return sqlfluff.format_args(ctx.filename)
      end,
      stdin = true,
      cwd = function(_, ctx)
        return sqlfluff.cwd(ctx.filename)
      end,
      require_cwd = true,
    },
    deno_fmt = {
      args = function(_, ctx)
        local extension = vim.fn.fnamemodify(ctx.filename, ":e")
        if extension ~= "" then
          return { "fmt", "-", "--ext=" .. extension }
        end
        return { "fmt", "-" }
      end,
    },
    prisma_fmt = {
      command = function()
        local root = fs.get_root()
        return root
          .. (
            os_utils.is_win() and "/node_modules/.bin/prisma.CMD"
            or "/node_modules/.bin/prisma"
          )
      end,
      condition = function(_, ctx)
        return vim.bo[ctx.buf].filetype == "prisma"
      end,
      args = { "format" },
      stdin = false,
    },
  },

  formatters_by_ft = require("config.packages").formatters_by_ft,
  format_on_save = false,
}
