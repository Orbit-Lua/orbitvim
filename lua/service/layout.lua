local M = {}

local cfg = require("service.config")
local core = require("service.core")
local data = require("service.data")
local borders = require("config.borders")
local str = require("utils.str")

---@param ui Service.UI
---@return string?
function M.active_ft(ui)
  if ui.scope == "buffer" then
    return ui.source_ft
  end
  return nil
end

---@param ui Service.UI
---@param category ServiceCategory
---@param ft string
---@return boolean
function M.is_ft_expanded(ui, category, ft)
  local key = core.ft_key(category, ft)
  if ui.expanded[key] ~= nil then
    return ui.expanded[key]
  end
  return ui.scope == "buffer"
end

---@param ui Service.UI
---@param category ServiceCategory
---@param name string
---@return boolean
function M.is_service_expanded(ui, category, name)
  return ui.expanded[core.service_key(category, name)] == true
end

---@param ui Service.UI
---@param category ServiceCategory
---@return integer
function M.content_lines(ui, category)
  local ft = M.active_ft(ui)
  if core.is_ordered_category(category) then
    local count = 0
    for _, group in ipairs(data.build_ft_groups(category, ft)) do
      count = count + 1
      if M.is_ft_expanded(ui, category, group.ft) then
        count = count + #group.names
      end
    end
    return count
  end

  local count = 0
  for _, service_entry in ipairs(data.service_entries(category, ft)) do
    local name = service_entry.name
    local meta = service_entry.meta
    count = count + 1
    if M.is_service_expanded(ui, category, name) then
      count = count + #(meta.ft or {})
    end
  end
  return count
end

---@return integer
function M.chrome_lines()
  return 4 + (cfg.layout.section_margin * 4)
end

---@param ui Service.UI
---@return vim.api.keyset.win_config
function M.make_win_cfg(ui)
  local win_cfg = cfg.window
  local win_width = math.min(
    vim.o.columns - win_cfg.editor_padding,
    math.max(
      cfg.min_w,
      math.min(cfg.max_w, vim.o.columns - win_cfg.width_margin)
    )
  )
  local natural = M.chrome_lines()
    + M.content_lines(ui, cfg.service_categories[ui.category_idx])
  local win_height = math.min(
    vim.o.lines - win_cfg.height_margin,
    math.max(cfg.min_h, math.min(cfg.max_h, natural))
  )
  return {
    relative = win_cfg.relative,
    width = win_width,
    height = win_height,
    row = math.floor((vim.o.lines - win_height) / 2),
    col = math.floor((vim.o.columns - win_width) / 2),
    style = win_cfg.style,
    border = borders.default,
    title = win_cfg.title,
    title_pos = win_cfg.title_pos,
    noautocmd = win_cfg.noautocmd,
  }
end

---@param ui Service.UI
---@param win_width integer
---@return string tabline, integer[][] tab_ranges, integer hint_byte, string hint
function M.build_tabline(ui, win_width)
  local tab_cfg = cfg.tabline
  local tabline = tab_cfg.prefix
  local tab_ranges = {}
  for i, category_name in ipairs(cfg.service_categories) do
    local lbl =
      string.format(tab_cfg.item_format, i, cfg.cat_label[category_name])
    local start_byte = #tabline
    tabline = tabline .. lbl
    tab_ranges[i] = { start_byte, #tabline }
  end

  local hint = (
    ui.scope == "buffer" and tab_cfg.buffer_scope_hint
    or tab_cfg.states_scope_hint
  )
    .. tab_cfg.hint_separator
    .. tab_cfg.help_hint
  local hint_pad = math.max(
    0,
    win_width
      - vim.fn.strdisplaywidth(tabline)
      - vim.fn.strdisplaywidth(hint)
      - tab_cfg.right_padding
  )
  local hint_byte = #tabline + hint_pad
  tabline = tabline .. string.rep(" ", hint_pad) .. hint

  return tabline, tab_ranges, hint_byte, hint
end

---@param ui Service.UI
---@param category ServiceCategory
---@return string
function M.scope_line(ui, category)
  local labels = cfg.labels
  local prefix = cfg.layout.line_prefix
  local sep = cfg.tabline.hint_separator
  if ui.scope == "buffer" then
    local ft = ui.source_ft or ""
    local name = ui.source_name or ""
    local label = name ~= "" and vim.fn.fnamemodify(name, ":t")
      or labels.no_name
    if ft == "" then
      return prefix
        .. labels.current_buffer
        .. ": "
        .. label
        .. sep
        .. labels.no_filetype
    end
    return prefix
      .. labels.current_buffer
      .. ": "
      .. label
      .. sep
      .. "ft="
      .. ft
      .. sep
      .. labels.showing_available
  end

  local summary = data.state_summary(category)
  return string.format(
    "%s%s: %s%s%d %s%s%d %s%s%d %s",
    prefix,
    labels.service_states,
    cfg.cat_label[category],
    sep,
    summary.enabled,
    labels.enabled,
    sep,
    summary.disabled,
    labels.disabled,
    sep,
    summary.total,
    labels.total
  )
end

---@param lines string[]
---@param win_width integer
function M.add_margin(lines, win_width)
  for _ = 1, cfg.layout.section_margin do
    table.insert(lines, str.fill_line("", win_width))
  end
end

return M
