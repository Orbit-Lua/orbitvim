---@type LazySpec[]
return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    opts = function()
      return require("config.linter")
    end,
    config = function(_, opts)
      require("runtime.linter").setup(opts)
    end,
  },
}
