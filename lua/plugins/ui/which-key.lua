local borders = require("config.borders")

---@type LazySpec[]
return {
  {
    "folke/which-key.nvim",
    lazy = false,
    keys = { "<leader>", "<c-r>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    cmd = "WhichKey",
    opts = function()
      dofile(vim.g.base46_cache .. "whichkey")

      ---@module "which-key"
      ---@type wk.Opts
      return {
        ---@type false | "classic" | "modern" | "helix"
        preset = "helix",
        win = {
          border = borders.default,
        },
      }
    end,
  },
}
