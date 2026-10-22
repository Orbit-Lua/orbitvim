-- config: https://github.com/folke/noice.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
---@type LazySpec[]
return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = function()
      return require("config.ui.noice")
    end,
    -- Notifications render through snacks.notifier.
    dependencies = { "MunifTanjim/nui.nvim" },
  },
}
