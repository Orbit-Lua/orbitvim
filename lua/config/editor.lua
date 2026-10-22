return {
  treesitter = {
    install_dir = vim.fn.stdpath("data") .. "/site",
  },

  context = {
    enable = true,
    multiwindow = false,
    max_lines = 3,
    min_window_height = 0,
    line_numbers = true,
    multiline_threshold = 20,
    trim_scope = "outer",
    mode = "cursor",
    separator = nil,
    zindex = 20,
    on_attach = nil,
  },

  autotag = {
    opts = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = false,
    },
    aliases = {
      pubxml = "xml",
      csproj = "xml",

      -- ref:
      -- luacheck: ignore
      -- https://github.com/windwp/nvim-ts-autotag/blob/88c1453db4ba7dd24131086fe51fdf74e587d275/lua/nvim-ts-autotag/config/plugin.lua#L162
      jsx = "typescriptreact",
    },
  },

  indent = {
    indent = { char = "│", highlight = "IblChar" },
    scope = { char = "│", highlight = "IblScopeChar" },
  },
}
