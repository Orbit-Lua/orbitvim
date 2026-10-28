---@type LazySpec[]
return {
  { "MunifTanjim/nui.nvim", lazy = true },
  {
    "Orbit-Lua/hangar.nvim",
    version = "^0.3",
    -- Startup readers of tool state load later on events, so configuring
    -- hangar at startup keeps saved intent available to them.
    lazy = false,
    priority = 900,
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
      require("features.hangar.runtime").setup()
    end,
  },
}
