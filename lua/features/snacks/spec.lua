-- https://github.com/folke/snacks.nvim?tab=readme-ov-file#-features
---@type LazySpec[]
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,

    opts = function()
      return require("features.snacks.config")
    end,

    keys = require("features.snacks.config.keys"),

    config = function(_, opts)
      require("features.snacks.runtime").setup_snacks(opts)
    end,
  },
}
