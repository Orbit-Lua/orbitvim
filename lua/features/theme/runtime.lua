local M = {}

function M.load_cache(name)
  local ok, err = pcall(function()
    dofile(vim.g.base46_cache .. name)
  end)
  if not ok then
    vim.notify("[theme] " .. tostring(err), vim.log.levels.WARN)
  end
end

return M
