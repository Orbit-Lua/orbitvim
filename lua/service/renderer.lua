local M = {}

local cfg = require("service.config")
local core = require("service.core")
local data = require("service.data")
local services = require("config.services")
local borders = require("config.borders")
local state_mod = require("service.state")
local ui_utils = require("utils.ui")
local order = require("service.order")
local table_view = require("service.table")

---@class Service.Renderer.State
---@field ui Service.UI?
---@field ns integer?
---@field debounce_timer uv_timer_t?

---@type Service.Renderer.State
local _state = { ui = nil, ns = nil, debounce_timer = nil }

---@param opts { ui: Service.UI, ns: integer }
function M.init(opts)
  _state.ui = opts.ui
  _state.ns = opts.ns
end

local function is_ft_expanded(category, ft)
  local key = core.ft_key(category, ft)
  if _state.ui.expanded[key] ~= nil then
    return _state.ui.expanded[key]
  end
  return _state.ui.scope == "buffer"
end

local function active_ft()
  if _state.ui.scope == "buffer" then
    return _state.ui.source_ft
  end
  return nil
end

local function content_lines(category)
  local ft = active_ft()
  if core.is_ordered_category(category) then
    local count = 0
    for _, group in ipairs(data.build_ft_groups(category, ft)) do
      count = count + 1
      if is_ft_expanded(category, group.ft) then
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
    if _state.ui.expanded[core.service_key(category, name)] then
      count = count + #(meta.ft or {})
    end
  end
  return count
end

---@return integer
local function chrome_lines()
  return 4 + (cfg.layout.section_margin * 4)
end

---@return vim.api.keyset.win_config
function M.make_win_cfg()
  local win_cfg = cfg.window
  local win_width = math.min(
    vim.o.columns - win_cfg.editor_padding,
    math.max(
      cfg.min_w,
      math.min(cfg.max_w, vim.o.columns - win_cfg.width_margin)
    )
  )
  local natural = chrome_lines()
    + content_lines(cfg.service_categories[_state.ui.category_idx])
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

---@param win_width integer
---@return string tabline, integer[][] tab_ranges, integer hint_byte, string hint
local function build_tabline(win_width)
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
    _state.ui.scope == "buffer" and tab_cfg.buffer_scope_hint
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

---@param category ServiceCategory
---@param icon_disp_w integer
---@return Service.Table.Column[]
local function build_columns(category, icon_disp_w)
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

local function package_label(meta)
  return meta.mason or cfg.labels.external
end

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

---@param category ServiceCategory
---@return string
local function scope_line(category)
  local labels = cfg.labels
  local prefix = cfg.layout.line_prefix
  local sep = cfg.tabline.hint_separator
  if _state.ui.scope == "buffer" then
    local ft = _state.ui.source_ft or ""
    local name = _state.ui.source_name or ""
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

local function build_ordered_rows(category)
  local labels = cfg.labels
  local rows = {}
  for _, group in ipairs(data.build_ft_groups(category, active_ft())) do
    local is_expanded = is_ft_expanded(category, group.ft)
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
          local icon = is_enabled and cfg.icons.enabled or cfg.icons.disabled
          local display_name = string.format("%d. %s", idx, name)
          local status_text, status_hl = data.entry_status(category, name, meta)
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

local function build_service_rows(category)
  local labels = cfg.labels
  local rows = {}
  for _, service_entry in ipairs(data.service_entries(category, active_ft())) do
    local name = service_entry.name
    local meta = service_entry.meta
    local is_enabled = state_mod.is_enabled(category, name)
    local icon = is_enabled and cfg.icons.enabled or cfg.icons.disabled
    local is_expanded = _state.ui.expanded[core.service_key(category, name)]
      == true
    local expand_icon = is_expanded and cfg.icons.expanded
      or cfg.icons.collapsed
    local name_w = (category == "lsp" or category == "dap") and cfg.col_name
      or cfg.col_tool
    local display_name = ui_utils.trunc(name, name_w)
    local status_text, status_hl = data.entry_status(category, name, meta)

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

---@param lines string[]
---@param win_width integer
local function add_margin(lines, win_width)
  for _ = 1, cfg.layout.section_margin do
    table.insert(lines, ui_utils.fill_line("", win_width))
  end
end

---@return nil
function M.render()
  if not (_state.ui.buf and vim.api.nvim_buf_is_valid(_state.ui.buf)) then
    return
  end
  _state.ui.help_open = false

  local category = cfg.service_categories[_state.ui.category_idx]
  local icon_disp_w = vim.fn.strdisplaywidth(cfg.icons.enabled)
  local wcfg = M.make_win_cfg()
  local win_width = wcfg.width
  local sep = string.rep(
    cfg.layout.separator_char,
    win_width - cfg.layout.separator_inset
  )

  local tabline, tab_ranges, hint_byte, hint = build_tabline(win_width)
  local columns = build_columns(category, icon_disp_w)
  local rows = core.is_ordered_category(category)
      and build_ordered_rows(category)
    or build_service_rows(category)

  local lines = {}
  local tabline_lnum, sep_lnum, scope_lnum, header_lnum

  add_margin(lines, win_width)
  table.insert(lines, ui_utils.fill_line(tabline, win_width))
  tabline_lnum = #lines
  add_margin(lines, win_width)
  table.insert(
    lines,
    ui_utils.fill_line(cfg.layout.line_prefix .. sep, win_width)
  )
  sep_lnum = #lines
  add_margin(lines, win_width)
  table.insert(lines, ui_utils.fill_line(scope_line(category), win_width))
  scope_lnum = #lines
  add_margin(lines, win_width)

  _state.ui.line_map = {}

  if #rows == 0 then
    local message = _state.ui.scope == "buffer"
        and cfg.labels.no_current_services
      or cfg.labels.no_category_services
    table.insert(
      lines,
      table_view.empty_line(message, win_width, cfg.table.empty_prefix)
    )
  else
    local col_hdr, row_lines, row_map = table_view.render({
      columns = columns,
      rows = rows,
      width = win_width,
      indent = cfg.table.indent,
      separator = cfg.table.separator,
      cell_padding = cfg.table.cell_padding,
    })
    table.insert(lines, ui_utils.fill_line(col_hdr, win_width))
    header_lnum = #lines

    local base = #lines
    vim.list_extend(lines, row_lines)
    for lnum, entry in pairs(row_map) do
      _state.ui.line_map[base + lnum] = entry
    end
  end

  vim.bo[_state.ui.buf].modifiable = true
  vim.api.nvim_buf_set_lines(_state.ui.buf, 0, -1, false, lines)
  vim.bo[_state.ui.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(_state.ui.buf, _state.ns, 0, -1)

  for i, range in ipairs(tab_ranges) do
    local tab_highlight = (i == _state.ui.category_idx)
        and "DiagnosticVirtualTextInfo"
      or "TabLine"
    ui_utils.buf_hl(
      _state.ui.buf,
      _state.ns,
      tab_highlight,
      tabline_lnum - 1,
      range[1],
      range[2]
    )
  end
  ui_utils.buf_hl(
    _state.ui.buf,
    _state.ns,
    "Comment",
    tabline_lnum - 1,
    hint_byte,
    hint_byte + #hint
  )
  ui_utils.buf_hl(_state.ui.buf, _state.ns, "Comment", sep_lnum - 1, 0, -1)
  ui_utils.buf_hl(_state.ui.buf, _state.ns, "Comment", scope_lnum - 1, 0, -1)
  if header_lnum then
    ui_utils.buf_hl(_state.ui.buf, _state.ns, "Comment", header_lnum - 1, 0, -1)
  end

  for lnum, entry in pairs(_state.ui.line_map) do
    local tree_hl = entry.kind == "detail" and "Comment" or "Title"
    local icon_hl = entry.kind == "ft_group" and "Title"
      or entry.kind == "detail" and "Comment"
      or state_mod.is_enabled(category, entry.name) and "DiagnosticOk"
      or "Comment"
    if entry.tree_byte and entry.tree_end_byte then
      ui_utils.buf_hl(
        _state.ui.buf,
        _state.ns,
        tree_hl,
        lnum - 1,
        entry.tree_byte,
        entry.tree_end_byte
      )
    end
    ui_utils.buf_hl(
      _state.ui.buf,
      _state.ns,
      icon_hl,
      lnum - 1,
      entry.icon_byte,
      entry.icon_end_byte or entry.icon_byte
    )
    ui_utils.buf_hl(
      _state.ui.buf,
      _state.ns,
      entry.status_hl,
      lnum - 1,
      entry.status_byte,
      entry.status_end_byte or entry.status_byte
    )
  end

  if _state.ui.win and vim.api.nvim_win_is_valid(_state.ui.win) then
    vim.api.nvim_win_set_config(_state.ui.win, {
      relative = "editor",
      width = wcfg.width,
      height = wcfg.height,
      row = wcfg.row,
      col = wcfg.col,
    })

    local cur = vim.api.nvim_win_get_cursor(_state.ui.win)[1]
    local first_entry_lnum, last_entry_lnum
    for lnum in pairs(_state.ui.line_map) do
      first_entry_lnum = first_entry_lnum and math.min(first_entry_lnum, lnum)
        or lnum
      last_entry_lnum = last_entry_lnum and math.max(last_entry_lnum, lnum)
        or lnum
    end
    if first_entry_lnum then
      if cur < first_entry_lnum then
        vim.api.nvim_win_set_cursor(_state.ui.win, { first_entry_lnum, 0 })
      elseif cur > last_entry_lnum then
        vim.api.nvim_win_set_cursor(_state.ui.win, { last_entry_lnum, 0 })
      end
    end
  end
end

---@return nil
function M.render_help()
  if not (_state.ui.buf and vim.api.nvim_buf_is_valid(_state.ui.buf)) then
    return
  end
  _state.ui.line_map = {}

  local win_width = vim.api.nvim_win_get_width(_state.ui.win)
  local sep = string.rep(
    cfg.layout.separator_char,
    win_width - cfg.layout.separator_inset
  )

  local lines = {}
  local section_lnums = {}

  local function render_section(title)
    add_margin(lines, win_width)
    table.insert(
      lines,
      ui_utils.fill_line(cfg.layout.line_prefix .. title, win_width)
    )
    section_lnums[#lines] = true
  end

  local function row(key, desc)
    table.insert(
      lines,
      ui_utils.fill_line(
        string.format(
          "%s%-" .. cfg.help.key_width .. "s %s",
          cfg.layout.line_prefix,
          key,
          desc
        ),
        win_width
      )
    )
  end

  table.insert(lines, ui_utils.fill_line("", win_width))
  table.insert(
    lines,
    ui_utils.fill_line(cfg.layout.line_prefix .. cfg.help.title, win_width)
  )
  table.insert(
    lines,
    ui_utils.fill_line(cfg.layout.line_prefix .. sep, win_width)
  )

  for _, section in ipairs(cfg.help.sections) do
    render_section(section.title)
    for _, help_row in ipairs(section.rows) do
      row(help_row[1], help_row[2])
    end
  end

  vim.bo[_state.ui.buf].modifiable = true
  vim.api.nvim_buf_set_lines(_state.ui.buf, 0, -1, false, lines)
  vim.bo[_state.ui.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(_state.ui.buf, _state.ns, 0, -1)

  for lnum in pairs(section_lnums) do
    ui_utils.buf_hl(_state.ui.buf, _state.ns, "Title", lnum - 1, 0, -1)
  end
end

---@return nil
function M.toggle_help()
  _state.ui.help_open = not _state.ui.help_open
  if _state.ui.help_open then
    M.render_help()
  else
    M.render()
  end
end

---@return nil
local function schedule_render()
  vim.schedule(function()
    if
      _state.ui.win
      and vim.api.nvim_win_is_valid(_state.ui.win)
      and not _state.ui.help_open
    then
      M.render()
    end
  end)
end

local DIAGNOSTIC_DEBOUNCE_MS = 500

---@return nil
local function schedule_render_debounced()
  if _state.debounce_timer then
    _state.debounce_timer:stop()
    _state.debounce_timer:close()
    _state.debounce_timer = nil
  end
  _state.debounce_timer = vim.uv.new_timer()
  _state.debounce_timer:start(DIAGNOSTIC_DEBOUNCE_MS, 0, function()
    _state.debounce_timer:stop()
    _state.debounce_timer:close()
    _state.debounce_timer = nil
    schedule_render()
  end)
end

---@return nil
function M.start_live_update()
  if _state.ui.live_augroup then
    return
  end
  _state.ui.live_augroup =
    vim.api.nvim_create_augroup("ServiceManagerLive", { clear = true })

  vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = _state.ui.live_augroup,
    callback = schedule_render,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = _state.ui.live_augroup,
    callback = schedule_render,
  })

  -- Re-render the linter tab when diagnostics change so counts stay current.
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = _state.ui.live_augroup,
    callback = function()
      if cfg.service_categories[_state.ui.category_idx] ~= "linter" then
        return
      end
      schedule_render_debounced()
    end,
  })

  -- Re-render the linter tab when a lint run completes so run-error state
  -- (binary not found, definition not found) stays current.
  vim.api.nvim_create_autocmd("User", {
    pattern = "NvimLintRunPost",
    group = _state.ui.live_augroup,
    callback = function()
      if cfg.service_categories[_state.ui.category_idx] ~= "linter" then
        return
      end
      schedule_render_debounced()
    end,
  })
end

---@return nil
function M.stop_live_update()
  if _state.debounce_timer then
    _state.debounce_timer:stop()
    _state.debounce_timer:close()
    _state.debounce_timer = nil
  end
  if _state.ui.live_augroup then
    pcall(vim.api.nvim_del_augroup_by_id, _state.ui.live_augroup)
    _state.ui.live_augroup = nil
  end
end

return M
