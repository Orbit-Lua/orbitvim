---@type LazySpec[]
return {
  {
    "Orbit-Lua/menu",
    dependencies = { "Orbit-Lua/volt" },
    keys = function()
      return require("features.menu.runtime").keys()
    end,
  },
}
