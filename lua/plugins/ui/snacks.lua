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
      local snacks = require("snacks")
      local redraw_range = snacks.util.redraw_range

      -- Wrap to suppress invalid window id error popups.
      snacks.util.redraw_range = function(...)
        pcall(redraw_range, ...)
      end

      snacks.setup(opts)
    end,
  },
}
