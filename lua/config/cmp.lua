local config = require("config")
local borders = require("config.borders")
local theme = require("config.theme")
local window = require("utils.window")
local utils_cmp = require("utils.cmp")

theme.load_cache("cmp")

vim.o.pumheight = select(2, window.get_completion_size())

local cmp = require("cmp")
local cmp_types = require("cmp.types")
local defaults = require("cmp.config.default")()
local should_auto_select = true
local is_ghost_text_enabled = false

-- https://github.com/hrsh7th/nvim-cmp/blob/b5311ab3ed9c846b585c0c15b7559be131ec4be9/doc/cmp.txt#L450
---@type cmp.ConfigSchema
local options = {
  window = {
    completion = {
      border = borders.cmp.window.completion,
      scrollbar = true,
      col_offset = -1,
      winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel,Search:None,FloatBorder:CmpBorder",
    },
    documentation = {
      border = borders.cmp.window.documentation,
      scrollbar = true,
      max_width = select(1, window.get_doc_size()),
      max_height = select(2, window.get_doc_size()),
      winhighlight = "Normal:CmpDoc,FloatBorder:CmpDocBorder",
    },
  },
  completion = {
    completeopt = "menu,menuone,noinsert"
      .. (should_auto_select and "" or ",noselect"),
  },
  preselect = should_auto_select and cmp_types.cmp.PreselectMode.Item
    or cmp_types.cmp.PreselectMode.None,
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = {
    ["<C-p>"] = cmp.mapping.select_prev_item({
      behavior = cmp_types.cmp.SelectBehavior.Select,
    }),
    ["<C-n>"] = cmp.mapping.select_next_item({
      behavior = cmp_types.cmp.SelectBehavior.Select,
    }),
    ["<C-j>"] = cmp.mapping.select_next_item({
      behavior = cmp_types.cmp.SelectBehavior.Select,
    }),
    ["<C-k>"] = cmp.mapping.select_prev_item({
      behavior = cmp_types.cmp.SelectBehavior.Select,
    }),
    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
    ["<C-d>"] = cmp.mapping.scroll_docs(4),

    -- `i` = insert mode, `c` = command mode, `s` = select mode
    ["<C-e>"] = cmp.mapping({
      i = function()
        if cmp.visible() then
          cmp.abort()
        else
          cmp.complete()
        end
      end,
      c = function()
        if cmp.visible() then
          cmp.abort()
        else
          cmp.complete()
        end
      end,
    }),

    ["<CR>"] = utils_cmp.confirm({
      select = should_auto_select,
    }),

    ["<Tab>"] = cmp.mapping(function(fallback)
      if (not cmp.visible()) and require("luasnip").expand_or_jumpable() then
        require("luasnip").expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if (not cmp.visible()) and require("luasnip").jumpable(-1) then
        require("luasnip").jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  },

  formatting = {
    fields = { "kind", "abbr", "menu" },

    -- entry, item
    format = function(_, item)
      local icons = config.icons.kinds
      local max_width = select(1, window.get_completion_size())
      if icons[item.kind] then
        -- with text
        -- item.kind = icons[item.kind] .. item.kind
        item.kind = icons[item.kind]
      end

      local widths = {
        abbr = vim.g.cmp_widths and vim.g.cmp_widths.abbr
          or math.floor(max_width * 4 / 7),
        menu = vim.g.cmp_widths and vim.g.cmp_widths.menu
          or math.floor(max_width * 3 / 7),
      }

      for key, width in pairs(widths) do
        if item[key] and vim.fn.strdisplaywidth(item[key]) > width then
          item[key] = vim.fn.strcharpart(item[key], 0, width - 1) .. "…"
        end
      end

      return item
    end,
  },

  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "path" },
    { name = "buffer" },
    { name = "lazydev" },
  },

  sorting = defaults.sorting,

  experimental = {
    ghost_text = is_ghost_text_enabled and {
      hl_group = "CmpGhostText",
    },
  },
}

return options
