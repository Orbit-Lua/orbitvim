---@type LazySpec[]
return {
  { "MunifTanjim/nui.nvim", lazy = true },
  {
    "Orbit-Lua/hangar.nvim",
    commit = "899f95ed3d6f4ee49f9c7ed99a962ae79b58d0bc",
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
