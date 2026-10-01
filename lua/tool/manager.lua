local M = {}

local tools = require("config.tools")
local data = require("tool.data")
local order = require("tool.order")
local state = require("tool.state")
local categories = require("tool.category")
local mason = require("tool.mason")

local function done(callback, success, err)
  if callback then
    callback(success, err)
  end
end

local function valid_category(category)
  return type(category) == "string"
    and type(tools[category]) == "table"
    and categories[category] ~= nil
end

local function definition(category, name)
  if not valid_category(category) or type(name) ~= "string" then
    return nil
  end
  return tools[category][name]
end

local function policy()
  local setting = require("config.tool_manager").missing_package_policy
  return setting == "manual" and "manual" or "auto"
end

---@param opts { category: ToolCategory, scope?: "buffer"|"states", source?: table }
---@return table?
function M.snapshot(opts)
  opts = opts or {}
  local category = opts.category
  if not valid_category(category) then
    return nil
  end

  local source = opts.source or {}
  local bufnr = source.bufnr or vim.api.nvim_get_current_buf()
  local ft = source.filetype
  if ft == nil and bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    ft = vim.bo[bufnr].filetype
  end
  local scope = opts.scope == "states" and "states" or "buffer"
  local entries
  if scope == "states" then
    entries = data.tool_entries(category)
  elseif ft and ft ~= "" then
    entries = data.tool_entries(category, ft)
  else
    entries = {}
  end
  local snapshot = {
    category = category,
    tools = {},
    groups = scope == "states" and data.build_ft_groups(category)
      or (ft and ft ~= "" and data.build_ft_groups(category, ft) or {}),
    summary = data.state_summary(category),
  }
  for _, entry in ipairs(entries) do
    local status, status_hl =
      data.entry_status(category, entry.name, entry.meta)
    if entry.meta.mason and mason.is_installing(entry.meta.mason) then
      status, status_hl = "installing", "DiagnosticInfo"
    end
    table.insert(snapshot.tools, {
      name = entry.name,
      meta = vim.deepcopy(entry.meta),
      status = status,
      status_hl = status_hl,
      enabled = state.is_enabled(category, entry.name),
    })
  end
  return snapshot
end

---@param selection { category: ToolCategory, name: string }
---@param on_complete fun(success: boolean, err?: string)?
---@return boolean
function M.toggle(selection, on_complete)
  local category, name =
    selection and selection.category, selection and selection.name
  local meta = definition(category, name)
  local handler = valid_category(category) and categories[category]
  if not meta or not handler or not handler.capabilities.toggle then
    done(on_complete, false, "unknown or non-toggleable tool")
    return false
  end

  local enabled = not state.is_enabled(category, name)
  local function apply()
    state.set_enabled(category, name, enabled)
    if handler.apply_runtime then
      handler.apply_runtime({ name = name, meta = meta, is_enabled = enabled })
    end
    done(on_complete, true)
  end

  if enabled and meta.mason then
    local installed, err = mason.package_status(meta.mason)
    if installed == false then
      if policy() == "manual" then
        local message = meta.mason .. " is not installed"
        done(on_complete, false, message)
        return false
      end
      return mason.install(meta.mason, function(success, install_err)
        if success then
          apply()
        else
          done(on_complete, false, install_err or "package installation failed")
        end
      end)
    elseif installed == nil then
      done(on_complete, false, err or "package status unavailable")
      return false
    end
  end

  apply()
  return true
end

---@param selection { category: ToolCategory, name: string }
---@param on_complete fun(success: boolean, err?: string)?
---@return boolean
function M.install(selection, on_complete)
  local category, name =
    selection and selection.category, selection and selection.name
  local meta = definition(category, name)
  local handler = valid_category(category) and categories[category]
  if not meta or not handler or not handler.capabilities.install then
    done(on_complete, false, "unknown or non-installable tool")
    return false
  end
  if handler.install then
    return handler.install(name, on_complete)
  end
  if not meta.mason then
    local err = "no install package for " .. name
    done(on_complete, false, err)
    return false
  end
  return mason.install(meta.mason, on_complete)
end

---@param selection { category: ToolCategory, filetype: string, name: string, direction: integer }
---@param on_complete fun(success: boolean, err?: string)?
---@return boolean
function M.reorder(selection, on_complete)
  local category = selection and selection.category
  local ft = selection and selection.filetype
  local name = selection and selection.name
  local direction = selection and selection.direction
  local meta = definition(category, name)
  local handler = valid_category(category) and categories[category]
  if
    not meta
    or (category ~= "formatter" and category ~= "linter")
    or not handler
    or not handler.capabilities.reorder
    or type(ft) ~= "string"
    or not vim.tbl_contains(meta.ft or {}, ft)
    or (direction ~= -1 and direction ~= 1)
  then
    done(on_complete, false, "invalid reorder selection")
    return false
  end

  local names = order.names_for_ft(category, ft)
  local index
  for i, current in ipairs(names) do
    if current == name then
      index = i
      break
    end
  end
  if not index or index + direction < 1 or index + direction > #names then
    done(on_complete, false, "tool is already at the order boundary")
    return false
  end
  names[index], names[index + direction] =
    names[index + direction], names[index]
  state.set_order(category, ft, names)
  if handler.apply_order then
    handler.apply_order({
      ft = ft,
      enabled_names = order.enabled_names_for_ft(category, ft, names),
    })
  end
  done(on_complete, true)
  return true
end

return M
