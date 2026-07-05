local M = {}

local window = require("utils.window")

function M.close_lazy_view()
  local ok, lazy_view = pcall(require, "lazy.view")

  if ok and lazy_view.visible() and lazy_view.view then
    lazy_view.view:close()
  end
end

function M.load_options()
  local function loader()
    local defaults_ok, _ = pcall(require, "config.defaults")
    local config_options_ok, _ = pcall(require, "config.options")

    if not defaults_ok or not config_options_ok then
      vim.notify(
        "Failed to load options. Please check your configuration.",
        vim.log.levels.ERROR
      )
    end
  end

  local win = window.get_editor_win()
  if win and win ~= vim.api.nvim_get_current_win() then
    vim.api.nvim_win_call(win, loader)
  else
    loader()
  end
end

return M
