---@type LazySpec[]
return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    cond = function()
      local vault = require("features.settings.config").get().notes.vault
      return vault ~= "" and vim.fn.isdirectory(vim.fn.expand(vault)) == 1
    end,
    ft = "markdown",
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = function()
      return require("features.notes.config")
    end,
    config = function(_, opts)
      require("features.notes.runtime").setup(opts)
    end,
  },
}
