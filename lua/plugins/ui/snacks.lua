-- https://github.com/folke/snacks.nvim?tab=readme-ov-file#-features
---@type LazySpec[]
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,

    opts = function()
      return require("config.snacks.options")
    end,

    keys = require("config.snacks.keys"),

    config = function(_, opts)
      require("runtime.ui").setup_snacks(opts)
    end,
  },
}
