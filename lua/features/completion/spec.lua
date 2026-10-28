---@type LazySpec[]
return {
  {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter", "LspAttach" },
    version = "1.*",
    dependencies = {
      {
        -- doc:
        -- https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets",
        build = function(plugin)
          require("features.completion.runtime").build_luasnip(plugin)
        end,
        opts = function()
          return require("features.completion.config").luasnip
        end,
        config = function(_, opts)
          require("features.completion.runtime").setup_luasnip(opts)
        end,
      },

      {
        "windwp/nvim-autopairs",
        opts = function()
          return require("features.completion.config").autopairs
        end,
        config = function(_, opts)
          require("nvim-autopairs").setup(opts)
        end,
      },

      {
        "folke/lazydev.nvim",
        ft = "lua",

        -- https://github.com/DrKJeff16/wezterm-types
        dependencies = {
          { "justinsgithub/wezterm-types", lazy = true },
        },

        opts = function()
          return require("features.completion.config").lazydev
        end,
      },
    },

    opts = function()
      require("features.theme.runtime").load_cache("blink")
      return require("features.completion.config.blink").build()
    end,

    main = "features.completion.runtime.blink",
  },
}
