local M = {}
local window = require("utils.window")

local function list_contains(list, value)
  return vim.tbl_contains(list, value)
end

local function get_kind_icon(kind)
  return require("config.icons").kinds[kind]
end

---@param opts blink.cmp.Config|{sources?: {compat?: string[]}}
local function setup_compat_sources(opts)
  opts.sources = opts.sources or {}
  opts.sources.default = opts.sources.default or {}
  opts.sources.providers = opts.sources.providers or {}

  for _, source in ipairs(opts.sources.compat or {}) do
    opts.sources.providers[source] = vim.tbl_deep_extend(
      "force",
      { name = source, module = "blink.compat.source" },
      opts.sources.providers[source] or {}
    )

    if
      type(opts.sources.default) == "table"
      and not list_contains(opts.sources.default, source)
    then
      table.insert(opts.sources.default, source)
    end
  end

  opts.sources.compat = nil
end

---@param opts blink.cmp.Config
local function setup_tab_mapping(opts)
  opts.keymap = opts.keymap or {}
  if opts.keymap["<Tab>"] then
    return
  end

  local tab_actions = {
    require("utils.cmp").map({ "snippet_forward" }),
    "fallback",
  }

  if opts.keymap.preset == "super-tab" then
    local ok, presets = pcall(require, "blink.cmp.keymap.presets")
    local super_tab = ok and presets.get("super-tab")["<Tab>"]
    if type(super_tab) == "table" and super_tab[1] then
      table.insert(tab_actions, 1, super_tab[1])
    end
  end

  opts.keymap["<Tab>"] = tab_actions
end

---@param opts blink.cmp.Config
local function setup_provider_kinds(opts)
  local providers = vim.tbl_get(opts, "sources", "providers") or {}
  for _, provider in pairs(providers) do
    ---@cast provider blink.cmp.SourceProviderConfig|{kind?: string}
    local kind = provider.kind
    if kind then
      local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
      local kind_idx = CompletionItemKind[kind]

      if not kind_idx then
        kind_idx = #CompletionItemKind + 1
        CompletionItemKind[kind_idx] = kind
        CompletionItemKind[kind] = kind_idx
      end

      local transform_items = provider.transform_items
      provider.transform_items = function(ctx, items)
        items = transform_items and transform_items(ctx, items) or items
        for _, item in ipairs(items) do
          item.kind = kind_idx
          item.kind_name = kind
          item.kind_icon = get_kind_icon(kind) or item.kind_icon or nil
        end
        return items
      end

      provider.kind = nil
    end
  end
end

local function apply_blink_window_sizes(opts, sizes)
  if type(opts) ~= "table" then
    return
  end

  local menu = vim.tbl_get(opts, "completion", "menu")
  local documentation_window =
    vim.tbl_get(opts, "completion", "documentation", "window")

  if menu then
    menu.max_height = sizes.completion.height
  end

  if documentation_window then
    documentation_window.max_width = sizes.documentation.width
    documentation_window.max_height = sizes.documentation.height
  end
end

local function update_blink_windows(sizes)
  local menu = package.loaded["blink.cmp.completion.windows.menu"]
  if type(menu) == "table" and menu.win and menu.win.config then
    menu.win.config.max_height = sizes.completion.height

    if menu.renderer and menu.context and menu.items then
      menu.renderer:draw(menu.context, menu.win:get_buf(), menu.items)
    end

    if type(menu.update_position) == "function" then
      menu.update_position()
    end
  end

  local docs = package.loaded["blink.cmp.completion.windows.documentation"]
  if type(docs) ~= "table" or not (docs.win and docs.win.config) then
    return
  end

  docs.win.config.max_width = sizes.documentation.width
  docs.win.config.max_height = sizes.documentation.height

  if type(docs.update_position) == "function" then
    docs.update_position()
  end
end

local function sync_blink_window_sizes(opts)
  local sizes = window.get_completion_float_sizes()

  vim.o.pumheight = sizes.completion.height

  apply_blink_window_sizes(opts, sizes)
  apply_blink_window_sizes(package.loaded["blink.cmp.config"], sizes)
  update_blink_windows(sizes)
end

local function setup_blink_window_resize(opts)
  sync_blink_window_sizes(opts)

  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = vim.api.nvim_create_augroup("OrbitVimBlinkResize", {
      clear = true,
    }),
    callback = function()
      sync_blink_window_sizes(opts)
    end,
  })
end

---@param opts blink.cmp.Config
function M.setup(opts)
  setup_compat_sources(opts)
  setup_tab_mapping(opts)
  setup_provider_kinds(opts)

  require("blink.cmp").setup(opts)

  setup_blink_window_resize(opts)
end

return M
