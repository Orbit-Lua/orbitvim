local theme = require("config.theme")

theme.load_cache("syntax")
theme.load_cache("treesitter")

---@type LazySpec[]
return {
  {
    -- https://github.com/nvim-treesitter/nvim-treesitter/issues/8350
    -- [Lua]: Invalid node type "substitute"
    -- Solution: delete nvim-treesitter manually and reinstall
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = { ":TSUpdate" },

    ---@module "nvim-treesitter"
    ---@type TSConfig
    ---@diagnostic disable-next-line
    opts = {
      install_dir = vim.fn.stdpath("data") .. "/site",
      ensure_installed = require("config.packages").treesitter_ensure_installed,
    },
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    opts = {
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
  },

  -- https://www.reddit.com/r/neovim/comments/1agjong/html_tags/
  -- https://github.com/andymass/vim-matchup?tab=readme-ov-file#installation
  {
    "andymass/vim-matchup",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    init = function()
      vim.g.matchup_treesitter_stopline = 500
      vim.g.matchup_matchparen_offscreen =
        { method = "popup", fullwidth = 1, border = 0 }
      require("match-up").setup({ ---@diagnostic disable-next-line
        treesitter = { stopline = 500 },
      })
    end,
    ---@type matchup.Config
    ---@diagnostic disable-next-line
    opts = { treesitter = { stopline = 500 } },
  },

  -- https://github.com/windwp/nvim-ts-autotag
  {
    "windwp/nvim-ts-autotag",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPre", "BufNewFile" },
    ---@type nvim-ts-autotag.PluginSetup
    ---@diagnostic disable-next-line
    opts = {
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
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "User FilePost",
    ---@type ibl.config
    opts = {
      indent = { char = "│", highlight = "IblChar" },
      scope = { char = "│", highlight = "IblScopeChar" },
    },
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
    build = { "npm install && cd app && npm install" },
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
    keys = {
      {
        "<leader>mp",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "markdown preview toggle",
      },
    },
  },
}
