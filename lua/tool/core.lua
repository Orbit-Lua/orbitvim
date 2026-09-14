local M = {}

local ordered_categories = {
  formatter = true,
  linter = true,
}

---@param category ToolCategory
---@return boolean
function M.is_ordered_category(category)
  return ordered_categories[category] == true
end

---@param category ToolCategory
---@param name string
---@return string
function M.tool_key(category, name)
  return category .. ":" .. name
end

---@param category ToolCategory
---@param ft string
---@return string
function M.ft_key(category, ft)
  return category .. ":ft:" .. ft
end

---@param category ToolCategory
---@return string
function M.order_key(category)
  return category .. "_order"
end

return M
