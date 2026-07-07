local M = {}

local cfg = require("service.config")
local core = require("service.core")
local mason = require("service.mason")
local state_mod = require("service.state")
local tooltip = require("service.tooltip")
local category_handlers = require("service.category")
local cursor = require("service.cursor")

---@class Service.Actions.State
---@field ui Service.UI?
---@field render (fun())?

---@type Service.Actions.State
local _state = { ui = nil, render = nil }

---@param opts { ui: Service.UI, tooltip_ns: integer, render: fun() }
function M.init(opts)
  _state.ui = opts.ui
  _state.render = opts.render
  tooltip.init({ ui = opts.ui, ns = opts.tooltip_ns })
end

---@return Service.Entry?
local function current_entry()
  return cursor.current_entry(_state.ui)
end

---@return nil
function M.show_tooltip_at_cursor()
  tooltip.show_at_cursor()
end

---@return nil
function M.do_toggle()
  local entry = current_entry()
  if not entry or not entry.meta then
    return
  end
  local category = cfg.service_categories[_state.ui.category_idx]
  local is_now_enabled = not state_mod.is_enabled(category, entry.name)

  if is_now_enabled and entry.meta.mason then
    local pkg, err = mason.get_package(entry.meta.mason)
    if pkg and not pkg:is_installed() then
      if cfg.missing_package_policy == "manual" then
        vim.notify(
          entry.meta.mason .. " is not installed; press i to install",
          vim.log.levels.WARN
        )
        return
      end

      if cfg.missing_package_policy == "auto" then
        mason.install(entry.meta.mason, function()
          state_mod.set_enabled(category, entry.name, true)
          category_handlers[category].apply_runtime({
            name = entry.name,
            meta = entry.meta,
            is_enabled = true,
          })
          _state.render()
        end)
        return
      end
    elseif not pkg then
      vim.notify("ServiceManager: " .. err, vim.log.levels.WARN)
    end
  end

  state_mod.set_enabled(category, entry.name, is_now_enabled)
  category_handlers[category].apply_runtime({
    name = entry.name,
    meta = entry.meta,
    is_enabled = is_now_enabled,
  })
  _state.render()
end

---@return nil
function M.do_install()
  local entry = current_entry()
  if not entry or not entry.meta then
    return
  end
  if not entry.meta.mason then
    vim.notify(
      "No mason package for "
        .. entry.name
        .. (entry.meta.note and (" — " .. entry.meta.note) or ""),
      vim.log.levels.WARN
    )
    return
  end
  mason.install(entry.meta.mason, _state.render)
end

---@param dir integer -1 for up, 1 for down
---@return nil
function M.do_reorder(dir)
  local entry = current_entry()
  if not entry or not entry.ft or not entry.order_names then
    return
  end
  local category = cfg.service_categories[_state.ui.category_idx]

  local names = vim.deepcopy(entry.order_names)
  local current_idx
  for i, n in ipairs(names) do
    if n == entry.name then
      current_idx = i
      break
    end
  end
  if not current_idx then
    return
  end

  local new_idx = current_idx + dir
  if new_idx < 1 or new_idx > #names then
    return
  end

  names[current_idx], names[new_idx] = names[new_idx], names[current_idx]

  if category == "linter" or category == "formatter" then
    state_mod.set_order(
      category --[[@as "formatter"|"linter"]],
      entry.ft,
      names
    )
  end

  local enabled_names = vim.tbl_filter(function(n)
    return state_mod.is_enabled(category, n)
  end, names)
  local handler = category_handlers[category]
  if handler and handler.apply_order then
    handler.apply_order({ ft = entry.ft, enabled_names = enabled_names })
  end

  _state.render()

  cursor.focus_match(_state.ui, function(e)
    return e.name == entry.name and e.ft == entry.ft
  end)
end

---@return nil
function M.toggle_expand()
  if _state.ui.help_open then
    return
  end
  local entry = current_entry()
  if not entry then
    return
  end
  local category = cfg.service_categories[_state.ui.category_idx]

  local key
  if core.is_ordered_category(category) and entry.ft then
    key = core.ft_key(category, entry.ft)
    local is_expanded = _state.ui.expanded[key]
    if is_expanded == nil then
      is_expanded = _state.ui.scope == "buffer"
    end
    _state.ui.expanded[key] = not is_expanded
  elseif entry.name then
    key = core.service_key(category, entry.name)
    _state.ui.expanded[key] = not _state.ui.expanded[key]
  else
    return
  end

  _state.render()
end

---@param idx integer
---@return nil
function M.switch_tab(idx)
  _state.ui.category_idx = idx
  _state.render()
  cursor.focus_first(_state.ui)
end

---@return nil
function M.toggle_scope()
  _state.ui.scope = _state.ui.scope == "buffer" and "states" or "buffer"
  _state.render()
  cursor.focus_first(_state.ui)
end

return M
