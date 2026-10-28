---@type LazySpec[]
return {
  {
    -- https://github.com/nvim-treesitter/nvim-treesitter/issues/8350
    -- [Lua]: Invalid node type "substitute"
    -- Solution: delete nvim-treesitter manually and reinstall
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = { ":TSUpdate" },
    init = function()
      require("features.theme.runtime").load_cache("syntax")
      require("features.theme.runtime").load_cache("treesitter")
      require("features.treesitter.runtime").setup()
    end,

    ---@module "nvim-treesitter"
    ---@type TSConfig
    ---@diagnostic disable-next-line
    opts = function()
      return require("features.treesitter.config").treesitter
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    opts = function()
      return require("features.treesitter.config").context
    end,
  },
  -- https://github.com/windwp/nvim-ts-autotag
  {
    "windwp/nvim-ts-autotag",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPre", "BufNewFile" },
    ---@type nvim-ts-autotag.PluginSetup
    ---@diagnostic disable-next-line
    opts = function()
      return require("features.treesitter.config").autotag
    end,
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },
}
