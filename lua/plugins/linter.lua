---@type LazySpec[]
return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    opts = function()
      vim.env.ESLINT_D_PPID = vim.fn.getpid()
      return require("config.linter")
    end,
    config = function(_, opts)
      require("config.linter.runtime").setup(opts)
    end,
  },
}
