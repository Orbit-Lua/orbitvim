local borders = require("config.borders")

---@type LazySpec[]
return {
  {
    "folke/which-key.nvim",
    lazy = false,
    keys = {
      "<leader>",
      "<c-r>",
      "<c-w>",
      '"',
      "'",
      "`",
      "c",
      "v",
      "g",
      { "<leader>wK", "<cmd>WhichKey <CR>", desc = "show all keymaps" },
      {
        "<leader>wk",
        function()
          vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
        end,
        desc = "query keymaps",
      },
    },
    cmd = "WhichKey",
    opts = function()
      local ui = require("utils.ui")
      ui.load_base46_cache("whichkey")

      ---@module "which-key"
      ---@type wk.Opts
      return {
        ---@type false | "classic" | "modern" | "helix"
        preset = "helix",
        win = {
          border = borders.default,
        },
        spec = {
          { "<leader>b", group = "buffer" },
          { "<leader>c", group = "code" },
          { "<leader>d", group = "debug" },
          { "<leader>f", group = "file/find" },
          { "<leader>g", group = "git" },
          { "<leader>m", group = "markdown" },
          { "<leader>s", group = "search" },
          { "<leader>t", group = "trouble/diagnostic" },
          { "<leader>u", group = "ui" },
          { "<leader>w", group = "whichkey" },
        },
      }
    end,
  },
}
