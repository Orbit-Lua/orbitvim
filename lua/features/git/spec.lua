---@type LazySpec[]
return {
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    init = function()
      require("features.theme.runtime").load_cache("git")
    end,
    opts = function()
      return require("features.git.config")
    end,
  },
}
