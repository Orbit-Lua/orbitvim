local M = {}
local window = require("utils.window")

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
  require("blink.cmp").setup(opts)

  setup_blink_window_resize(opts)
end

return M
