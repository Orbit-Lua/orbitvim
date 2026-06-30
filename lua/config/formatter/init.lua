-- config for conform.nvim

local fs = require("utils.fs")
local os_utils = require("utils.os")

return {
  default_format_opts = {
    timeout_ms = 5000,
    async = true, -- not recommended to change
    quiet = false, -- not recommended to change
    lsp_format = "fallback", -- not recommended to change
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
    ["sqlfluff"] = {
      command = "sqlfluff",
      args = function()
        for _, file in ipairs(fs.sqlfluff_pattern) do
          local path = fs.get_root() .. "/" .. file
          if vim.uv.fs_stat(path) ~= nil then
            return { "format", "-" }
          end
        end

        local config_path = fs.config_path
          .. "/lua/config/db/template/sqlfluff.cfg"
        return { "format", "--config", config_path, "-" }
      end,
      stdin = true,
      -- cwd = util.root_file(fs.sqlfluff_pattern),
      cwd = function(_, ctx)
        return fs.get_root(ctx.dirname)
      end,
      require_cwd = true,
    },
    ["sql_formatter"] = {
      args = function()
        local current_dir = vim.fn.expand("%:h")
        local current_config_path =
          string.format("%s/.sql-formatter.json", current_dir)

        return { "--config", current_config_path }
      end,
    },
    ["deno_fmt"] = {
      args = function()
        local file_extension = vim.fn.expand("%:e")

        if file_extension ~= "" then
          return { "fmt", "-", "--ext=" .. file_extension }
        end

        return { "fmt", "-" }
      end,
    },
    ["prisma_fmt"] = {
      command = function()
        if os_utils.is_win() then
          return vim.fn.getcwd() .. "/node_modules/.bin/prisma.CMD"
        end

        return ""
      end,
      condition = function(_, ctx)
        return vim.bo[ctx.buf].filetype == "prisma"
      end,
      args = { "format" },
      stdin = false,
    },
  },

  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
    sh = { "shfmt" },

    -- web dev
    css = { "deno_fmt" },
    html = { "deno_fmt" },

    -- eslint_d is used for fix, not complete formatting, so deno_fmt is needed
    typescript = { "deno_fmt", "eslint_d" },
    javascript = { "deno_fmt", "eslint_d" },

    typescriptreact = { "deno_fmt", "eslint_d" },
    javascriptreact = { "deno_fmt", "eslint_d" },
    jsx = { "deno_fmt", "eslint_d" },

    json = { "deno_fmt" },
    jsonc = { "deno_fmt" },
    toml = { "tombi" },
    prisma = { "prisma_fmt" },
    cs = { "csharpier" },

    -- markdown
    ["markdown"] = { "markdownlint-cli2", "markdown-toc" },
    ["markdown.mdx"] = { "markdownlint-cli2", "markdown-toc" },
  },

  format_on_save = false,

  -- format_on_save = function()
  --   if vim.bo.filetype == "prisma" then
  --     return
  --   end
  --
  --   -- These options will be passed to conform.format()
  --   return { timeout_ms = 2000, lsp_fallback = true }
  -- end,
}
