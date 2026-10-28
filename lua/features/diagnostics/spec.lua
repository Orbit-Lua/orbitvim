---@type LazySpec[]
return {
  {
    -- ref: https://github.com/folke/trouble.nvim/blob/main/docs/examples.md
    "folke/trouble.nvim",

    opts = function()
      return require("features.diagnostics.config").trouble
    end,
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
          require("features.diagnostics.runtime").open_lsp_references()
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
    event = "User FilePost",
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
    opts = function()
      return require("features.diagnostics.config").todo
    end,

    config = function(_, opts)
      require("features.theme.runtime").load_cache("todo")
      require("todo-comments").setup(opts)
    end,
  },
}
