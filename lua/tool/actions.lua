local M = {}

local cfg = require("tool.config")
local core = require("tool.core")
local mason = require("tool.mason")
local state_mod = require("tool.state")
local tooltip = require("tool.ui.tooltip")
local category_handlers = require("tool.category")
local cursor = require("tool.ui.cursor")

---@param ctx Tool.UIContext
---@return Tool.UIEntry?
local function current_entry(ctx)
  return cursor.current_entry(ctx.ui)
end

---@return nil
function M.show_tooltip_at_cursor(ctx)
  tooltip.show_at_cursor(ctx)
end

---@return nil
function M.do_toggle(ctx)
  local entry = current_entry(ctx)
  if not entry or not entry.meta then
    return
  end
  local category = cfg.tool_categories[ctx.ui.category_idx]
  local handler = category_handlers[category]
  if not handler or not handler.capabilities.toggle then
    vim.notify(
      category .. " tools cannot be enabled or disabled",
      vim.log.levels.INFO
    )
    return
  end
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
          handler.apply_runtime({
            name = entry.name,
            meta = entry.meta,
            is_enabled = true,
          })
          ctx.render()
        end)
        return
      end
    elseif not pkg then
      vim.notify("ToolManager: " .. err, vim.log.levels.WARN)
    end
  end

  state_mod.set_enabled(category, entry.name, is_now_enabled)
  handler.apply_runtime({
    name = entry.name,
    meta = entry.meta,
    is_enabled = is_now_enabled,
  })
  ctx.render()
end

---@return nil
function M.do_install(ctx)
  local entry = current_entry(ctx)
  if not entry or not entry.meta then
    return
  end
  local category = cfg.tool_categories[ctx.ui.category_idx]
  local handler = category_handlers[category]
  if not handler or not handler.capabilities.install then
    vim.notify(
      category .. " tools cannot be installed here",
      vim.log.levels.INFO
    )
    return
  end
  if handler.install then
    handler.install(entry.name, ctx.render)
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
  mason.install(entry.meta.mason, ctx.render)
end

---@param dir integer -1 for up, 1 for down
---@return nil
function M.do_reorder(ctx, dir)
  local entry = current_entry(ctx)
  if not entry or not entry.ft or not entry.order_names then
    return
  end
  local category = cfg.tool_categories[ctx.ui.category_idx]
  local handler = category_handlers[category]
  if not handler or not handler.capabilities.reorder then
    return
  end

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
  if handler and handler.apply_order then
    handler.apply_order({ ft = entry.ft, enabled_names = enabled_names })
  end

  ctx.render()

  cursor.focus_match(ctx.ui, function(e)
    return e.name == entry.name and e.ft == entry.ft
  end)
end

---@return nil
function M.toggle_expand(ctx)
  if ctx.ui.help_open then
    return
  end
  local entry = current_entry(ctx)
  if not entry then
    return
  end
  local category = cfg.tool_categories[ctx.ui.category_idx]

  local key
  if core.is_ordered_category(category) and entry.ft then
    key = core.ft_key(category, entry.ft)
    local is_expanded = ctx.ui.expanded[key]
    if is_expanded == nil then
      is_expanded = ctx.ui.scope == "buffer"
    end
    ctx.ui.expanded[key] = not is_expanded
  elseif entry.name then
    key = core.tool_key(category, entry.name)
    ctx.ui.expanded[key] = not ctx.ui.expanded[key]
  else
    return
  end

  ctx.render()
end

---@param idx integer
---@return nil
function M.switch_tab(ctx, idx)
  ctx.ui.category_idx = idx
  ctx.render()
  cursor.focus_first(ctx.ui)
end

---@return nil
function M.toggle_scope(ctx)
  ctx.ui.scope = ctx.ui.scope == "buffer" and "states" or "buffer"
  ctx.render()
  cursor.focus_first(ctx.ui)
end

return M
