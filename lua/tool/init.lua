local M = {}
local view
local state = { category = 1, expanded = {} }

function M.close()
  if view then
    view:close()
  end
end

---Inject the registry, persistence paths, view options and adapter owners.
---A repeated call replaces them and drops cached state, failures and the open
---session; it is rejected while a toggle or installation is still running.
---@param opts Tool.Options
function M.setup(opts)
  local config = require("tool.config")
  config.validate(opts)
  if config.configured() then
    local manager = require("tool.manager")
    if manager.busy() then
      error("tool.setup: an operation is in flight; retry after it finishes", 2)
    end
    M.close()
    manager.reset()
    require("tool.state").reset()
    state = { category = 1, expanded = {} }
  end
  config.set(opts)
end

function M.open()
  if view and view:active() then
    vim.api.nvim_set_current_win(view.body.winid)
    return
  end
  M.close()
  local buffer = vim.api.nvim_get_current_buf()
  local source = {
    bufnr = buffer,
    filetype = vim.bo[buffer].filetype,
    name = vim.api.nvim_buf_get_name(buffer),
  }
  state.scope = "buffer"
  state.help = false
  view = require("tool.ui.view").new(source, state, function(closed)
    if view == closed then
      view = nil
    end
  end)
end

return M
