---@type LazyConfig
return {
  defaults = { lazy = true },
  install = { colorscheme = { "nvchad" } },

  ui = {
    icons = {
      ft = "",
      lazy = "󰂠 ",
      loaded = "",
      not_loaded = "",
    },
  },

  performance = {
    rtp = {
      -- Names of $VIMRUNTIME/plugin files without their extension.
      disabled_plugins = {
        "gzip",
        "matchit",
        "netrwPlugin",
        "rplugin",
        "spellfile",
        "tarPlugin",
        "tutor",
        "zipPlugin",
      },
    },
  },

  rocks = {
    enabled = false,
    herorocks = false,
  },
}
