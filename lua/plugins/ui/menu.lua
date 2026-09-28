---@type LazySpec[]
return {
  {
    "Orbit-Lua/menu",
    dependencies = { "Orbit-Lua/volt" },
    keys = require("runtime.menu").keys(),
  },
}
