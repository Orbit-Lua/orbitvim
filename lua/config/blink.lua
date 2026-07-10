local config = require("config")
local borders = require("config.borders")
local theme = require("config.theme")
local utils_cmp = require("utils.cmp")
local window = require("utils.window")

theme.load_cache("blink")

local function get_detail(item)
  local detail = item.detail
  if type(detail) == "table" then
    detail = table.concat(detail, "\n")
  end

  if type(detail) ~= "string" or detail == "" then
    return nil
  end

  return vim.trim(detail)
end

local function draw_documentation(opts)
  local item = opts.item
  local lines = {}
  local documentation_lines = {}

  if
    type(item.documentation) == "string"
    or type(item.documentation) == "table"
  then
    documentation_lines = vim.lsp.util.convert_input_to_markdown_lines(
      item.documentation,
      documentation_lines
    )
  end

  local detail = get_detail(item)
  if
    detail and not table.concat(documentation_lines, "\n"):find(detail, 1, true)
  then
    local filetype = vim.bo.filetype:gsub("%..*$", "")
    table.insert(lines, ("```%s"):format(filetype))
    vim.list_extend(lines, vim.split(detail, "\n", { trimempty = true }))
    table.insert(lines, "```")
  end

  vim.list_extend(lines, documentation_lines)

  if #lines == 0 then
    opts.default_implementation()
    return
  end

  -- FIXME: deprecated
  vim.lsp.util.stylize_markdown(opts.window:get_buf(), lines, {
    max_width = opts.window.config.max_width,
  })
end

local initial_sizes = window.get_completion_float_sizes()

---@type blink.cmp.Config
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
      utils_cmp.map({ "snippet_forward", "ai_nes", "ai_accept" }),
      "fallback",
    },
    ["<S-Tab>"] = { "snippet_backward", "fallback" },
  },

  appearance = {
    use_nvim_cmp_as_default = false,
    nerd_font_variant = "mono",
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
      max_height = initial_sizes.completion.height,
      winhighlight = "Normal:BlinkCmpMenu,CursorLine:BlinkCmpMenuSelection,Search:None,FloatBorder:BlinkCmpMenuBorder",
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
      draw = draw_documentation,
      window = {
        border = borders.cmp.window.documentation,
        max_width = initial_sizes.documentation.width,
        max_height = initial_sizes.documentation.height,
        winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
      },
    },
    ghost_text = {
      enabled = vim.g.ai_cmp,
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
    compat = {},
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
