local M = {}

local function listed_buffers()
  if vim.t.bufs and #vim.t.bufs > 0 then
    return vim.t.bufs
  end

  return vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf)
      and vim.api.nvim_get_option_value("buflisted", { buf = buf })
  end, vim.api.nvim_list_bufs())
end

local function current_index(buffers)
  local current = vim.api.nvim_get_current_buf()
  for index, buf in ipairs(buffers) do
    if buf == current then
      return index
    end
  end
end

function M.next()
  local buffers = listed_buffers()
  if #buffers == 0 then
    return
  end

  local index = current_index(buffers) or 0
  vim.api.nvim_set_current_buf(buffers[index == #buffers and 1 or index + 1])
end

function M.prev()
  local buffers = listed_buffers()
  if #buffers == 0 then
    return
  end

  local index = current_index(buffers) or 1
  vim.api.nvim_set_current_buf(buffers[index == 1 and #buffers or index - 1])
end

return M
