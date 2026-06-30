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
      local ui = require("utils.ui")
      ui.load_base46_cache("devicons")
      return { override = require("nvchad.icons.devicons") }
    end,
  },
}
