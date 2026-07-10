local borders = require("config.borders")

---@type LazySpec[]
return {
  {
    -- ref: https://github.com/folke/trouble.nvim/blob/main/docs/examples.md
    "folke/trouble.nvim",
    lazy = false,

    opts = {

      ---@type table<string, trouble.Mode>
      modes = {
        ---@diagnostic disable-next-line
        diagnostic_preview_float = {
          mode = "diagnostics",
          preview = {
            type = "float",
            relative = "editor",
            border = borders.default,
            title = " Preview ",
            title_pos = "center",
            position = { 0, -2 },
            size = { width = 0.3, height = 0.3 },
            zindex = 200,
          },
        },
      },
    },
    cmd = "Trouble",
    keys = {
      {
        "<leader>td",
        "<cmd>Trouble diagnostic_preview_float toggle win.position=bottom<cr>",
        desc = "diagnostics (trouble)",
      },
      {
        "<leader>tD",
        "<cmd>Trouble diagnostic_preview_float toggle filter.buf=0 win.position=bottom<cr>",
        desc = "buffer diagnostics (trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false win.position=right<cr>",
        desc = "symbols (trouble)",
      },
      {
        "<leader>cL",
        --- WORKAROUND: refresh will cause syntax highlight mess, so close and open again
        function()
          local trouble = require("trouble")

          ---@diagnostic disable-next-line
          trouble.close({ mode = "lsp" })
          trouble.open({
            mode = "lsp",
            auto_refresh = false,
            win = {
              position = "right",
            },
            focus = false,
          })
        end,
        desc = "lsp definitions / references / ... (trouble)",
      },
      {
        "<leader>tL",
        "<cmd>Trouble loclist toggle win.position=bottom<cr>",
        desc = "location list (trouble)",
      },
      {
        "<leader>tQ",
        "<cmd>Trouble qflist toggle win.position=bottom<cr>",
        desc = "quickfix list (trouble)",
      },
    },
  },

  {
    "folke/todo-comments.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>st",
        function()
          ---@diagnostic disable: undefined-field
          require("snacks").picker.todo_comments()
        end,
        desc = "Todo",
      },
      {
        "<leader>sT",
        function()
          ---@diagnostic disable: undefined-field
          require("snacks").picker.todo_comments({
            keywords = { "TODO", "FIX", "FIXME", "WORKAROUND" },
          })
        end,
        desc = "Todo/Fix/Fixme/Workaround",
      },
    },

    ---@module "todo-comments"
    ---@type TodoConfig
    opts = {
      keywords = {
        WORKAROUND = {
          icon = " ",
          color = "warning",
        },
      },
    },

    config = function(_, opts)
      require("config.theme").load_cache("todo")
      require("todo-comments").setup(opts)
    end,
  },
}
