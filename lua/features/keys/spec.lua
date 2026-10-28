---@type LazySpec[]
return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = {
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
      require("features.theme.runtime").load_cache("whichkey")

      ---@module "which-key"
      ---@type wk.Opts
      return require("features.keys.config")
    end,
  },
}
