local config = require("config")
local borders = require("config.borders")
local theme = require("config.theme")
local window = require("utils.window")

theme.load_cache("cmp")

vim.o.pumheight = select(2, window.get_completion_size())

local completion_width = select(1, window.get_completion_size())
local documentation_width = select(1, window.get_doc_size())
local documentation_height = select(2, window.get_doc_size())

---@type blink.cmp.Config
local options = {
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
    ["<Tab>"] = { "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "fallback" },
  },

  appearance = {
    use_nvim_cmp_as_default = true,
    nerd_font_variant = "normal",
    kind_icons = config.icons.kinds,
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
      max_height = select(2, window.get_completion_size()),
      winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel,Search:None,FloatBorder:CmpBorder",
      draw = {
        columns = {
          { "kind_icon" },
          { "label", "label_description", gap = 1 },
          { "source_name" },
        },
        components = {
          label = {
            width = { fill = true, max = math.floor(completion_width * 4 / 7) },
          },
          label_description = {
            width = { max = math.floor(completion_width * 2 / 7) },
          },
          source_name = {
            width = { max = math.floor(completion_width * 1 / 7) },
          },
        },
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
      window = {
        border = borders.cmp.window.documentation,
        max_width = documentation_width,
        max_height = documentation_height,
        winhighlight = "Normal:CmpDoc,FloatBorder:CmpDocBorder",
      },
    },
    ghost_text = {
      enabled = false,
    },
  },

  sources = {
    default = { "lazydev", "lsp", "path", "snippets", "buffer" },
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

return options
