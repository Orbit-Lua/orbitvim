---@type LazySpec[]
return {
  -- https://www.reddit.com/r/neovim/comments/1agjong/html_tags/
  -- https://github.com/andymass/vim-matchup?tab=readme-ov-file#installation
  {
    "andymass/vim-matchup",
    -- Upstream reads these globals while loading and advises against lazy loading.
    lazy = false,
    init = function()
      vim.g.matchup_treesitter_stopline = 500
      vim.g.matchup_matchparen_offscreen =
        { method = "popup", fullwidth = 1, border = 0 }
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "User FilePost",
    ---@type ibl.config
    opts = function()
      return require("features.editor.config").indent
    end,
    config = function(_, opts)
      require("features.theme.runtime").load_cache("blankline")

      local hooks = require("ibl.hooks")
      hooks.register(
        hooks.type.WHITESPACE,
        hooks.builtin.hide_first_space_indent_level
      )
      require("ibl").setup(opts)

      require("features.theme.runtime").load_cache("blankline")
    end,
  },
}
