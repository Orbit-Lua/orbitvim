---@type LazySpec[]
return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    cond = function()
      local vault = require("config.settings").get().notes.vault
      return vault ~= "" and vim.fn.isdirectory(vim.fn.expand(vault)) == 1
    end,
    ft = "markdown",
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = function()
      return require("config.notes")
    end,
    config = function(_, opts)
      require("runtime.notes").setup(opts)
    end,
  },
}
