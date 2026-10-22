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
          require("runtime.completion").build_luasnip(plugin)
        end,
        opts = function()
          return require("config.completion").luasnip
        end,
        config = function(_, opts)
          require("runtime.completion").setup_luasnip(opts)
        end,
      },

      {
        "windwp/nvim-autopairs",
        opts = function()
          return require("config.completion").autopairs
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
          return require("config.completion").lazydev
        end,
      },
    },

    opts = function()
      require("core.theme").load_cache("blink")
      return require("config.blink").build()
    end,

    main = "runtime.completion.blink",
  },
}
