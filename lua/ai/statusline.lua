local M = {}

---@param bufnr integer
---@return boolean
function M.is_available(bufnr)
  local minuet = package.loaded.minuet
  local config = minuet and minuet.config
  if
    not config
    or type(config.provider) ~= "string"
    or not vim.api.nvim_buf_is_valid(bufnr)
  then
    return false
  end

  local ok, provider = pcall(require, "minuet.backends." .. config.provider)
  if not ok or type(provider.is_available) ~= "function" then
    return false
  end

  local available_ok, available = pcall(provider.is_available)
  if not available_ok or not available then
    return false
  end

  local predicates = config.enable_predicates or {}
  local predicate_ok, enabled = pcall(vim.api.nvim_buf_call, bufnr, function()
    for _, predicate in ipairs(predicates) do
      if not predicate() then
        return false
      end
    end
    return true
  end)

  return predicate_ok and enabled
end

return M
