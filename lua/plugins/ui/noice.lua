local borders = require("config.borders")
local window = require("utils.window")
local config = require("config")

-- config: https://github.com/folke/noice.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
---@type LazySpec[]
return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      ---@type NoiceRouteConfig[]
      --- refer to: https://github.com/folke/noice.nvim/blob/main/lua/noice/config/routes.lua
      routes = {
        {
          view = "notify",
          filter = {
            event = "msg_show",
            any = vim.tbl_map(function(msg)
              return { find = msg }
            end, config.message_ignored.msg_show),
          },
          opts = { skip = true },
        },

        {
          view = "mini",
          filter = {
            event = "lsp",
            kind = "progress",
            any = vim.tbl_map(function(msg)
              return { find = msg }
            end, config.message_ignored.progress),
          },
          opts = { skip = true },
        },
      },

      cmdline = {
        enabled = true,
        view = "cmdline_popup",
      },

      -- This will catch vim.ui.select event, use snacks ui select override solve this problem
      messages = {
        enabled = true,
      },

      popupmenu = {
        enabled = true,
        backend = "nui",
      },

      lsp = {
        -- Override markdown rendering so that cmp and other plugins use treesitter
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },

        hover = {
          enabled = true,
          silent = true,
          ---@type NoiceViewOptions
          opts = {
            border = borders.lsp.hover,
            size = {
              max_width = select(1, window.get_doc_size()),
              max_height = select(2, window.get_doc_size()),
            },
          },
        },

        signature = {
          enabled = true,
          auto_open = {
            enabled = true,
            trigger = true,
            luasnip = true,
            throttle = 50,
          },
          ---@type NoiceViewOptions
          opts = {
            focusable = false,
            border = borders.lsp.signature_help,
            size = {
              max_width = select(1, window.get_doc_size()),
              max_height = select(2, window.get_doc_size()),
            },
          },
        },

        progress = {
          enabled = true,
        },

        -- Turn off this because it blocks many important messages from language servers ["window/showMessage"]
        message = {
          enabled = false,
        },
      },

      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },

      ---@type NoiceConfigViews
      views = {
        popup = {
          win_options = {
            winhighlight = {
              Normal = "CmpPmenu",
              FloatBorder = "CmpBorder",
            },
          },
        },
        mini = {
          position = {
            row = -3,
            col = "100%",
          },
        },
        ---@type NoiceViewOptions
        popupmenu = {
          position = "bottom",
        },
        ---@type NoiceViewOptions
        cmdline_popup = {
          border = borders.noice.cmdline,
          position = {
            col = 0.5,
            row = 0.3,
          },
        },
        -- rows must differ by at least 2.5
        ---@type NoiceViewOptions
        cmdline_popupmenu = {
          border = borders.noice.cmdline,
          position = {
            col = 0.5,
            row = 0.56,
          },
        },
      },
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
  },
}
