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
    dependencies = {
      "Orbit-Lua/volt",
    },
    lazy = false,
    config = function()
      require("nvchad")
    end,
  },

  {
    "nvim-mini/mini.icons",
    lazy = false,
    opts = {},
    config = function(_, opts)
      require("mini.icons").setup(opts)
      _G.MiniIcons.mock_nvim_web_devicons()
    end,
  },
}
