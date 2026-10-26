local icons = require("config.icons")
local borders = require("config.borders")
local utils_cmp = require("utils.cmp")
local window = require("utils.window")

local M = {}

---@return blink.cmp.Config
function M.build()
  local initial_sizes = window.get_completion_float_sizes()
  return {
    snippets = {
      preset = "luasnip",
    },

    keymap = {
      preset = "enter",
      ["<C-p>"] = { "select_prev", "fallback" },
      ["<C-n>"] = { "select_next", "fallback" },
      ["<C-j>"] = { "select_next", "fallback" },
      ["<C-k>"] = { "select_prev", "fallback" },
      ["<C-S>"] = {
        "show",
        "show_documentation",
        "hide_documentation",
      },
      ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      ["<C-d>"] = { "scroll_documentation_down", "fallback" },
      ["<C-e>"] = {
        function(cmp)
          if cmp.is_visible() then
            cmp.hide()
            return true
          end
          cmp.show()
          return true
        end,
      },
      ["<C-y>"] = { "select_and_accept" },
      ["<Tab>"] = {
        utils_cmp.map({ "snippet_forward" }),
        "fallback",
      },
      ["<S-Tab>"] = { "snippet_backward", "fallback" },
    },

    appearance = {
      use_nvim_cmp_as_default = false,
      nerd_font_variant = "mono",
      kind_icons = icons.kinds,
    },

    completion = {
      accept = {
        create_undo_point = true,
        auto_brackets = {
          enabled = true,
        },
      },
      list = {
        selection = {
          preselect = true,
          auto_insert = true,
        },
      },
      menu = {
        border = borders.cmp.window.completion,
        max_height = initial_sizes.completion.height,
        winhighlight = table.concat({
          "Normal:BlinkCmpMenu",
          "CursorLine:BlinkCmpMenuSelection",
          "Search:None",
          "FloatBorder:BlinkCmpMenuBorder",
        }, ","),
        draw = {
          treesitter = { "lsp" },
          columns = {
            { "kind_icon" },
            { "label", "label_description", gap = 1 },
            { "source_name" },
          },
          components = {
            label = {
              ---@diagnostic disable-next-line: assign-type-mismatch
              width = { fill = true, max = window.completion_width_part(4, 7) },
            },
            label_description = {
              ---@diagnostic disable-next-line: assign-type-mismatch
              width = { max = window.completion_width_part(2, 7) },
            },
            source_name = {
              ---@diagnostic disable-next-line: assign-type-mismatch
              width = { max = window.completion_width_part(1, 7) },
            },
          },
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        draw = function(opts)
          return require("runtime.completion.blink").draw_documentation(opts)
        end,
        window = {
          border = borders.cmp.window.documentation,
          max_width = initial_sizes.documentation.width,
          max_height = initial_sizes.documentation.height,
          winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
        },
      },
      ghost_text = {
        enabled = false,
      },
    },

    cmdline = {
      enabled = true,
      keymap = {
        preset = "cmdline",
        ["<Right>"] = false,
        ["<Left>"] = false,
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
      },
      completion = {
        list = { selection = { preselect = false } },
        menu = {
          auto_show = function()
            return vim.fn.getcmdtype() == ":"
          end,
        },
        ghost_text = { enabled = true },
      },
    },

    sources = {
      default = { "lazydev", "lsp", "path", "snippets", "buffer" },
      per_filetype = {
        lua = { inherit_defaults = true, "lazydev" },
      },
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
        lsp = {
          fallbacks = {},
        },
      },
    },

    fuzzy = {
      implementation = "prefer_rust_with_warning",
    },
  }
end

return M
