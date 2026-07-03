local ft = require("utils.ft")

---@type LazySpec[]
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format({ lsp_format = "fallback" })
        end,
        desc = "format file",
        mode = { "n", "x" },
      },
    },
    opts = function()
      local opts = require("config.formatter")
      local state_mod = require("service.state")
      local order = require("service.order")

      -- Inject sqlfluff for SQL filetypes before filtering
      if state_mod.is_enabled("formatter", "sqlfluff") then
        for _, filetype in ipairs(ft.sql_ft) do
          opts.formatters_by_ft[filetype] = opts.formatters_by_ft[filetype]
            or {}
          table.insert(opts.formatters_by_ft[filetype], "sqlfluff")
        end
      end

      -- Apply saved priority order then filter disabled formatters.
      for filetype, fmts in pairs(opts.formatters_by_ft) do
        opts.formatters_by_ft[filetype] =
          order.enabled_names_for_ft("formatter", filetype, fmts)
      end

      return opts
    end,
  },
}
