local M = {}
local view
local state = { category = 1, expanded = {} }

function M.close()
  if view then
    view:close()
  end
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
