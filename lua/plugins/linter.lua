---@type LazySpec[]
return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    opts = function()
      -- runtime.linter filters this table; config.linter stays the activation
      -- source for Tool Manager.
      return vim.deepcopy(require("config.linter"))
    end,
    config = function(_, opts)
      require("runtime.linter").setup(opts)
    end,
  },
}
