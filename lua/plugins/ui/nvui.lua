---@type LazySpec[]
return {
  {
    "Orbit-Lua/nv-base46",
    build = function()
      require("base46").load_all_highlights()
    end,
  },

  {
    "Orbit-Lua/nv-ui",
    lazy = false,
    config = function()
      require("nvchad")
    end,
  },
}
