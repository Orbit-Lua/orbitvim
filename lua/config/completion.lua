return {
  luasnip = { history = true, updateevents = "TextChanged,TextChangedI" },
  autopairs = {
    fast_wrap = {},
    disable_filetype = { "TelescopePrompt", "vim" },
  },
  lazydev = {
    library = {
      {
        path = "nv-ui/nvchad_types",
        mods = { "ui" },
        words = { "nvchad", "nvui" },
      },
      { path = "snacks.nvim", words = { "snacks", "snacks.nvim" } },
      { path = "noice.nvim", words = { "noice", "noice.nvim" } },
      { path = "comet.nvim", words = { "Comet", "comet.nvim" } },
      { path = "blink.cmp/lua/blink/cmp", words = { "blink%.cmp" } },
      { path = "wezterm-types", mods = { "wezterm", "module.wezterm" } },
    },
  },
}
