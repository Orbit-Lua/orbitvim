---@type LazySpec[]
return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    cond = vim.fn.isdirectory(vim.fn.expand("~") .. "/OneDrive/Knowledge_Base")
      == 1,
    lazy = true,
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
