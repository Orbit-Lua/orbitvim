local theme = require("core.theme")

---@type LazySpec[]
return {
  {
    -- https://github.com/nvim-treesitter/nvim-treesitter/issues/8350
    -- [Lua]: Invalid node type "substitute"
    -- Solution: delete nvim-treesitter manually and reinstall
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = { ":TSUpdate" },
    init = function()
      theme.load_cache("syntax")
      theme.load_cache("treesitter")
      require("runtime.treesitter").setup()
    end,

    ---@module "nvim-treesitter"
    ---@type TSConfig
    ---@diagnostic disable-next-line
    opts = function()
      return require("config.editor").treesitter
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    opts = function()
      return require("config.editor").context
    end,
  },

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

  -- https://github.com/windwp/nvim-ts-autotag
  {
    "windwp/nvim-ts-autotag",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPre", "BufNewFile" },
    ---@type nvim-ts-autotag.PluginSetup
    ---@diagnostic disable-next-line
    opts = function()
      return require("config.editor").autotag
    end,
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "User FilePost",
    ---@type ibl.config
    opts = function()
      return require("config.editor").indent
    end,
    config = function(_, opts)
      theme.load_cache("blankline")

      local hooks = require("ibl.hooks")
      hooks.register(
        hooks.type.WHITESPACE,
        hooks.builtin.hide_first_space_indent_level
      )
      require("ibl").setup(opts)

      theme.load_cache("blankline")
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function(plugin)
      require("runtime.markdown").build_preview(plugin)
    end,
    keys = {
      {
        "<leader>mp",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "markdown preview toggle",
      },
    },
  },
}
