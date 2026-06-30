local os = require("utils.os")

---@type LazySpec[]
return {
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "LspAttach" },
    dependencies = {
      {
        -- doc:
        -- https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets",
        build = (function()
          if os.is_win() then
            return "make CC=gcc INCLUDE_DIR=-I../lua51_include LDLIBS='C:/Program Files/Neovim/bin/lua51.dll'"
              .. "install_jsregexp"
          end

          return "make install_jsregexp"
        end)(),
        opts = { history = true, updateevents = "TextChanged,TextChangedI" },
        config = function(_, opts)
          require("luasnip").config.set_config(opts)

          local ls = require("luasnip")
          ls.filetype_extend("jsx", { "javascript", "javascriptreact" })

          require("config.snippets")
        end,
      },

      {
        "windwp/nvim-autopairs",
        opts = {
          fast_wrap = {},
          disable_filetype = { "TelescopePrompt", "vim" },
        },
        config = function(_, opts)
          require("nvim-autopairs").setup(opts)
          local cmp_autopairs = require("nvim-autopairs.completion.cmp")
          require("cmp").event:on(
            "confirm_done",
            cmp_autopairs.on_confirm_done()
          )
        end,
      },

      {
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
      },

      {
        "folke/lazydev.nvim",
        ft = "lua",

        -- https://github.com/DrKJeff16/wezterm-types
        dependencies = {
          { "justinsgithub/wezterm-types", lazy = true },
        },

        opts = {
          library = {
            {
              path = "nv-ui/nvchad_types",
              mods = { "ui" },
              words = { "nvchad", "nvui" },
            },
            { path = "snacks.nvim", words = { "snacks", "snacks.nvim" } },
            { path = "noice.nvim", words = { "noice", "noice.nvim" } },
            { path = "comet.nvim", words = { "Comet", "comet.nvim" } },
            { path = "nvim-cmp/lua/cmp/types", words = { "nvim%-cmp" } },
            { path = "wezterm-types", mods = { "wezterm", "module.wezterm" } },
          },
        },
      },
    },

    opts = function()
      return require("config.cmp")
    end,

    main = "utils.cmp",
  },
}
