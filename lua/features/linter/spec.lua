---@type LazySpec[]
return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    opts = function()
      -- features.linter.runtime filters this table; features.linter.config stays the activation
      -- source for Hangar.
      return vim.deepcopy(require("features.linter.config"))
    end,
    config = function(_, opts)
      require("features.linter.runtime").setup(opts)
    end,
  },
}
