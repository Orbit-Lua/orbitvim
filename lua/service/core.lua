local M = {}

local ordered_categories = {
  formatter = true,
  linter = true,
}

---@param category ServiceCategory
---@return boolean
function M.is_ordered_category(category)
  return ordered_categories[category] == true
end

---@param category ServiceCategory
---@param name string
---@return string
function M.service_key(category, name)
  return category .. ":" .. name
end

---@param category ServiceCategory
---@param ft string
---@return string
function M.ft_key(category, ft)
  return category .. ":ft:" .. ft
end

---@param category ServiceCategory
---@return string
function M.order_key(category)
  return category .. "_order"
end

return M
