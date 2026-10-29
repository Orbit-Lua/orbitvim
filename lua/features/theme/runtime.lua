local M = {}

function M.ensure_cache()
  for _, name in ipairs({ "defaults", "statusline" }) do
    if not vim.uv.fs_stat(vim.g.base46_cache .. name) then
      require("base46").compile()
      return
    end
  end
end

function M.load_cache(name)
  local ok, err = pcall(function()
    dofile(vim.g.base46_cache .. name)
  end)
  if not ok then
    vim.notify("[theme] " .. tostring(err), vim.log.levels.WARN)
  end
end

return M
