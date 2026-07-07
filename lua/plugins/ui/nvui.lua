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
    "nvim-mini/mini.icons",
    opts = {},
    config = function(_, opts)
      local mini_icons = require("mini.icons")
      mini_icons.setup(opts)
      _G.MiniIcons.mock_nvim_web_devicons()
    end,
  },
}
