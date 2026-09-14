local M = {}

---@param list table
---@param key string
---@return table
M.unique_by_key = function(list, key)
  local result = {}
  local seen = {}

  for _, item in ipairs(list) do
    local identifier = item[key]

    if identifier and not seen[identifier] then
      seen[identifier] = true
      table.insert(result, item)
    end
  end

  return result
end
return M
