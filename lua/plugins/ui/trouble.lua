---@type LazySpec[]
local borders = require("config.borders")
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
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>tD",
        "<cmd>Trouble diagnostic_preview_float toggle filter.buf=0 win.position=bottom<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false win.position=right<cr>",
        desc = "Symbols (Trouble)",
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
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>tL",
        "<cmd>Trouble loclist toggle win.position=bottom<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>tQ",
        "<cmd>Trouble qflist toggle win.position=bottom<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },

  {
    "folke/todo-comments.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>tt", "<cmd>TodoTelescope<cr>", desc = "Open ToDo Telescope" },
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
  },
}
