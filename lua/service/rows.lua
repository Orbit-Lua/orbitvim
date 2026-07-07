local M = {}

local cfg = require("service.config")
local core = require("service.core")
local data = require("service.data")
local services = require("config.services")
local state_mod = require("service.state")
local str = require("utils.str")
local order = require("service.order")
local layout = require("service.layout")

---@param meta Service.Meta
---@return string
local function package_label(meta)
  return meta.mason or cfg.labels.external
end

---@param is_enabled boolean
---@param status_hl string
---@return string icon
---@return string highlight_group
local function service_icon(is_enabled, status_hl)
  if not is_enabled then
    return cfg.icons.disabled, "ServiceMuted"
  end
  if status_hl == "DiagnosticError" then
    return cfg.icons.error, "DiagnosticError"
  elseif status_hl == "DiagnosticWarn" then
    return cfg.icons.warning, "DiagnosticWarn"
  end
  return cfg.icons.enabled, "DiagnosticOk"
end

---@return integer
function M.service_icon_width()
  local width = 0
  for _, icon in ipairs({
    cfg.icons.enabled,
    cfg.icons.disabled,
    cfg.icons.warning,
    cfg.icons.error,
  }) do
    width = math.max(width, vim.fn.strdisplaywidth(icon))
  end
  return width
end

---@param category ServiceCategory
---@param icon_disp_w integer
---@return Service.Table.Column[]
function M.build_columns(category, icon_disp_w)
  local labels = cfg.labels.columns
  local cell_padding = cfg.table.cell_padding
  local name_w = (category == "lsp" or category == "dap") and cfg.col_name
    or cfg.col_tool
  local name_label = core.is_ordered_category(category)
      and labels.grouped_service
    or labels.service
  return {
    { key = "tree", label = "", width = cfg.table.tree_width },
    { key = "icon", label = "", width = icon_disp_w + (cell_padding * 2) },
    { key = "name", label = name_label, width = name_w },
    { key = "package", label = labels.package, width = cfg.col_package },
    { key = "status", label = labels.status, grow = true },
  }
end

---@param category ServiceCategory
---@param name string
---@param meta Service.Meta
---@return table[]
local function ft_order_rows(category, name, meta)
  local rows = {}
  if category ~= "formatter" and category ~= "linter" then
    for _, ft in ipairs(meta.ft or {}) do
      table.insert(rows, { ft = ft })
    end
    return rows
  end

  for _, ft in ipairs(meta.ft or {}) do
    local names = order.names_for_ft(category, ft)
    local idx
    for i, candidate in ipairs(names) do
      if candidate == name then
        idx = i
        break
      end
    end
    table.insert(rows, { ft = ft, idx = idx, total = #names, names = names })
  end
  table.sort(rows, function(a, b)
    return a.ft < b.ft
  end)
  return rows
end

---@param ui Service.UI
---@param category ServiceCategory
---@return Service.Table.Row[]
local function build_ordered_rows(ui, category)
  local labels = cfg.labels
  local rows = {}
  for _, group in ipairs(data.build_ft_groups(category, layout.active_ft(ui))) do
    local is_expanded = layout.is_ft_expanded(ui, category, group.ft)
    local expand_icon = is_expanded and cfg.icons.expanded
      or cfg.icons.collapsed
    local label = string.format(
      "%s (%d %s)",
      group.ft,
      #group.names,
      #group.names == 1 and labels.tool_singular or labels.tool_plural
    )
    table.insert(rows, {
      cells = {
        tree = expand_icon,
        icon = "",
        name = label,
        package = "",
        status = labels.global_order,
      },
      icon_cell = "icon",
      entry = {
        name = group.ft,
        kind = "ft_group",
        ft = group.ft,
        order_names = group.names,
        meta = nil,
        icon_byte = 0,
        status_byte = 0,
        status_hl = "Comment",
      },
    })

    if is_expanded then
      for idx, name in ipairs(group.names) do
        local meta = services[category][name]
        if meta then
          local is_enabled = state_mod.is_enabled(category, name)
          local display_name = string.format("%d. %s", idx, name)
          local status_text, status_hl = data.entry_status(category, name, meta)
          local icon, icon_hl = service_icon(is_enabled, status_hl)
          table.insert(rows, {
            cells = {
              tree = "",
              icon = icon,
              name = display_name,
              package = package_label(meta),
              status = status_text,
            },
            icon_cell = "icon",
            entry = {
              name = name,
              kind = "service",
              ft = group.ft,
              order_names = group.names,
              meta = meta,
              icon_byte = 0,
              icon_hl = icon_hl,
              status_byte = 0,
              status_hl = status_hl,
            },
          })
        end
      end
    end
  end
  return rows
end

---@param ui Service.UI
---@param category ServiceCategory
---@return Service.Table.Row[]
local function build_service_rows(ui, category)
  local labels = cfg.labels
  local rows = {}
  for _, service_entry in
    ipairs(data.service_entries(category, layout.active_ft(ui)))
  do
    local name = service_entry.name
    local meta = service_entry.meta
    local is_enabled = state_mod.is_enabled(category, name)
    local is_expanded = layout.is_service_expanded(ui, category, name)
    local expand_icon = is_expanded and cfg.icons.expanded
      or cfg.icons.collapsed
    local name_w = (category == "lsp" or category == "dap") and cfg.col_name
      or cfg.col_tool
    local display_name = str.trunc(name, name_w)
    local status_text, status_hl = data.entry_status(category, name, meta)
    local icon, icon_hl = service_icon(is_enabled, status_hl)

    table.insert(rows, {
      cells = {
        tree = expand_icon,
        icon = icon,
        name = display_name,
        package = package_label(meta),
        status = status_text,
      },
      icon_cell = "icon",
      entry = {
        name = name,
        kind = "service",
        meta = meta,
        icon_byte = 0,
        icon_hl = icon_hl,
        status_byte = 0,
        status_hl = status_hl,
      },
    })

    if is_expanded then
      for _, row in ipairs(ft_order_rows(category, name, meta)) do
        local detail
        if row.idx then
          detail = string.format(
            "%s %-" .. labels.detail_ft_width .. "s %s %d/%d",
            labels.detail_ft_prefix,
            row.ft,
            labels.detail_order,
            row.idx,
            row.total
          )
        else
          detail = labels.detail_ft_prefix .. " " .. row.ft
        end
        table.insert(rows, {
          cells = {
            tree = "",
            icon = "",
            name = detail,
            package = "",
            status = "",
          },
          icon_cell = "name",
          entry = {
            name = name,
            kind = "detail",
            ft = row.ft,
            order_names = row.names,
            meta = meta,
            icon_byte = 0,
            status_byte = 0,
            status_hl = "Comment",
          },
        })
      end
    end
  end
  return rows
end

---@param ui Service.UI
---@param category ServiceCategory
---@return Service.Table.Column[] columns
---@return Service.Table.Row[] rows
function M.build(ui, category)
  local icon_disp_w = M.service_icon_width()
  local columns = M.build_columns(category, icon_disp_w)
  local row_items = core.is_ordered_category(category)
      and build_ordered_rows(ui, category)
    or build_service_rows(ui, category)
  return columns, row_items
end

return M
