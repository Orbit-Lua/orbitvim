local M = {}

local core = require("tool.core")
local tools = require("config.tools")
local state_mod = require("tool.state")

---@param names string[]
---@return table<string, boolean>
local function to_set(names)
  local set = {}
  for _, name in ipairs(names) do
    set[name] = true
  end
  return set
end

---@param names string[]
---@param seen table<string, boolean>
---@param out string[]
local function append_unseen(names, seen, out)
  for _, name in ipairs(names) do
    if not seen[name] then
      table.insert(out, name)
      seen[name] = true
    end
  end
end

---@param category ToolCategory
---@param ft string
---@return string[]
local function tool_names_for_ft(category, ft)
  local names = {}
  for name, meta in pairs(tools[category] or {}) do
    if vim.tbl_contains(meta.ft or {}, ft) then
      table.insert(names, name)
    end
  end
  table.sort(names)
  return names
end

---@param category ToolCategory
---@param ft string
---@return string[]?
local function configured_order(category, ft)
  if not core.is_ordered_category(category) then
    return nil
  end
  return state_mod.get_order(category --[[@as "formatter"|"linter"]], ft)
    or tools[category .. "_defaults"][ft]
end

---@param category ToolCategory
---@param ft string
---@param names string[]?
---@return string[]
function M.names_for_ft(category, ft, names)
  local candidates = names and vim.deepcopy(names)
    or tool_names_for_ft(category, ft)
  local candidate_set = to_set(candidates)
  local order = configured_order(category, ft)
  if not order then
    return candidates
  end

  local seen = {}
  local ordered = {}
  for _, name in ipairs(order) do
    if candidate_set[name] and not seen[name] then
      table.insert(ordered, name)
      seen[name] = true
    end
  end
  append_unseen(candidates, seen, ordered)
  return ordered
end

---@param category ToolCategory
---@param ft string
---@param names string[]?
---@return string[]
function M.enabled_names_for_ft(category, ft, names)
  return vim.tbl_filter(function(name)
    return tools[category][name] == nil or state_mod.is_enabled(category, name)
  end, M.names_for_ft(category, ft, names))
end

---@param category ToolCategory
---@return Tool.FtGroup[]
function M.build_ft_groups(category)
  local ft_set = {}
  for _, meta in pairs(tools[category] or {}) do
    for _, ft in ipairs(meta.ft or {}) do
      ft_set[ft] = true
    end
  end

  local filetypes = vim.tbl_keys(ft_set)
  table.sort(filetypes)

  local groups = {}
  for _, ft in ipairs(filetypes) do
    table.insert(groups, { ft = ft, names = M.names_for_ft(category, ft) })
  end
  return groups
end

return M
