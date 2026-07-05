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

  {
    "nvim-tree/nvim-web-devicons",
    opts = function()
      require("config.theme").load_cache("devicons")
      return { override = require("nvchad.icons.devicons") }
    end,
  },
}
