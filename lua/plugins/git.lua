---@type LazySpec[]
return {
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    init = function()
      require("core.theme").load_cache("git")
    end,
    opts = function()
      return require("config.git")
    end,
  },
}
