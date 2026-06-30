local M = {}

local cfg = require("service.config")
local core = require("service.core")
local data = require("service.data")
local services = require("config.services")
local borders = require("config.borders")
local state_mod = require("service.state")
local ui_utils = require("utils.ui")
local order = require("service.order")

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
  return _state.ui.expanded[core.ft_key(category, ft)] ~= false
end

local function content_lines(category)
  if core.is_ordered_category(category) then
    local count = 0
    for _, group in ipairs(data.build_ft_groups(category)) do
      count = count + 1
      if is_ft_expanded(category, group.ft) then
        count = count + #group.names
      end
    end
    return count
  end

  local count = vim.tbl_count(services[category])
  for name, meta in pairs(services[category]) do
    if _state.ui.expanded[core.service_key(category, name)] then
      count = count + #(meta.ft or {})
    end
  end
  return count
end

---@return vim.api.keyset.win_config
function M.make_win_cfg()
  local win_width = math.min(
    vim.o.columns - 2,
    math.max(cfg.min_w, math.min(cfg.max_w, vim.o.columns - 4))
  )
  local natural = 4
    + content_lines(cfg.service_categories[_state.ui.category_idx])
  local win_height =
    math.min(vim.o.lines - 2, math.max(cfg.min_h, math.min(cfg.max_h, natural)))
  return {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = math.floor((vim.o.lines - win_height) / 2),
    col = math.floor((vim.o.columns - win_width) / 2),
    style = "minimal",
    border = borders.default,
    title = " Service Manager ",
    title_pos = "center",
    noautocmd = true,
  }
end

---@param win_width integer
---@return string tabline, integer[][] tab_ranges, integer hint_byte, string hint
local function build_tabline(win_width)
  local tabline = "  "
  local tab_ranges = {}
  for i, category_name in ipairs(cfg.service_categories) do
    local lbl = "  " .. i .. " " .. cfg.cat_label[category_name] .. "  "
    local start_byte = #tabline
    tabline = tabline .. lbl
    tab_ranges[i] = { start_byte, #tabline }
  end

  local hint = "press g? for help"
  local hint_pad = math.max(
    0,
    win_width
      - vim.fn.strdisplaywidth(tabline)
      - vim.fn.strdisplaywidth(hint)
      - 2
  )
  local hint_byte = #tabline + hint_pad
  tabline = tabline .. string.rep(" ", hint_pad) .. hint

  return tabline, tab_ranges, hint_byte, hint
end

---@param category ServiceCategory
---@param icon_disp_w integer
---@return string
local function build_col_header(category, icon_disp_w)
  local name_w = (category == "lsp" or category == "dap") and cfg.col_name
    or cfg.col_tool
  local name_label = core.is_ordered_category(category) and "Filetype / Service"
    or "Service"
  return string.rep(" ", cfg.pad_flat + 2 + icon_disp_w + 2)
    .. ui_utils.rpad(name_label, name_w)
    .. "  "
    .. ui_utils.rpad("Package", cfg.col_package)
    .. "  "
    .. "Status"
end

local function package_label(meta)
  return meta.mason or "external"
end

local function service_entries(category)
  local flat = {}
  for name, meta in pairs(services[category]) do
    table.insert(flat, { name = name, meta = meta })
  end
  table.sort(flat, function(a, b)
    return a.name < b.name
  end)
  return flat
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

---@param lines string[]
---@param win_width integer
---@param prefix string
---@param status_text string
---@return integer status_byte
local function append_status_line(lines, win_width, prefix, status_text)
  local status_w = math.max(1, win_width - vim.fn.strdisplaywidth(prefix))
  table.insert(
    lines,
    ui_utils.fill_line(
      prefix .. ui_utils.trunc(status_text, status_w),
      win_width
    )
  )
  return #prefix
end

local function render_ordered_category(lines, category, win_width, icon_disp_w)
  local name_w = cfg.col_tool
  for _, group in ipairs(data.build_ft_groups(category)) do
    local is_expanded = is_ft_expanded(category, group.ft)
    local expand_icon = is_expanded and cfg.icons.expanded
      or cfg.icons.collapsed
    local label = string.format(
      "%s (%d %s)",
      group.ft,
      #group.names,
      #group.names == 1 and "tool" or "tools"
    )
    local prefix = string.rep(" ", cfg.pad_flat)
      .. expand_icon
      .. " "
      .. string.rep(" ", icon_disp_w + 2)
      .. ui_utils.rpad(ui_utils.trunc(label, name_w), name_w)
      .. "  "
      .. ui_utils.rpad("", cfg.col_package)
      .. "  "
    local status_byte =
      append_status_line(lines, win_width, prefix, "global order")
    _state.ui.line_map[#lines] = {
      name = group.ft,
      kind = "ft_group",
      ft = group.ft,
      order_names = group.names,
      meta = nil,
      icon_byte = cfg.pad_flat,
      status_byte = status_byte,
      status_hl = "Comment",
    }

    if is_expanded then
      for idx, name in ipairs(group.names) do
        local meta = services[category][name]
        if meta then
          local is_enabled = state_mod.is_enabled(category, name)
          local icon = is_enabled and cfg.icons.enabled or cfg.icons.disabled
          local display_name = string.format("%d. %s", idx, name)
          local status_text, status_hl = data.entry_status(category, name, meta)
          local icon_gap =
            string.rep(" ", icon_disp_w - vim.fn.strdisplaywidth(icon) + 2)
          local row_prefix = string.rep(" ", cfg.pad_flat + 2)
            .. icon
            .. icon_gap
            .. ui_utils.rpad(ui_utils.trunc(display_name, name_w), name_w)
            .. "  "
            .. ui_utils.rpad(
              ui_utils.trunc(package_label(meta), cfg.col_package),
              cfg.col_package
            )
            .. "  "
          local row_status_byte =
            append_status_line(lines, win_width, row_prefix, status_text)
          _state.ui.line_map[#lines] = {
            name = name,
            kind = "service",
            ft = group.ft,
            order_names = group.names,
            meta = meta,
            icon_byte = cfg.pad_flat + 2,
            status_byte = row_status_byte,
            status_hl = status_hl,
          }
        end
      end
    end
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
  local sep = string.rep("─", win_width - 4)

  local tabline, tab_ranges, hint_byte, hint = build_tabline(win_width)
  local col_hdr = build_col_header(category, icon_disp_w)

  local lines = {
    ui_utils.fill_line("", win_width),
    ui_utils.fill_line(tabline, win_width),
    ui_utils.fill_line("  " .. sep, win_width),
    ui_utils.fill_line(col_hdr, win_width),
  }
  _state.ui.line_map = {}

  if core.is_ordered_category(category) then
    render_ordered_category(lines, category, win_width, icon_disp_w)
  else
    for _, service_entry in ipairs(service_entries(category)) do
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

      local icon_gap =
        string.rep(" ", icon_disp_w - vim.fn.strdisplaywidth(icon) + 2)
      local prefix = string.rep(" ", cfg.pad_flat)
        .. expand_icon
        .. " "
        .. icon
        .. icon_gap
        .. ui_utils.rpad(display_name, name_w)
        .. "  "
        .. ui_utils.rpad(
          ui_utils.trunc(package_label(meta), cfg.col_package),
          cfg.col_package
        )
        .. "  "
      local status_byte =
        append_status_line(lines, win_width, prefix, status_text)
      _state.ui.line_map[#lines] = {
        name = name,
        kind = "service",
        meta = meta,
        icon_byte = cfg.pad_flat + 2,
        status_byte = status_byte,
        status_hl = status_hl,
      }

      if is_expanded then
        for _, row in ipairs(ft_order_rows(category, name, meta)) do
          local detail
          if row.idx then
            detail =
              string.format("ft %-18s order %d/%d", row.ft, row.idx, row.total)
          else
            detail = "ft " .. row.ft
          end
          local detail_prefix = string.rep(" ", cfg.pad_flat + 4) .. detail
          table.insert(lines, ui_utils.fill_line(detail_prefix, win_width))
          _state.ui.line_map[#lines] = {
            name = name,
            kind = "detail",
            ft = row.ft,
            order_names = row.names,
            meta = meta,
            icon_byte = cfg.pad_flat + 4,
            status_byte = #detail_prefix,
            status_hl = "Comment",
          }
        end
      end
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
      1,
      range[1],
      range[2]
    )
  end
  ui_utils.buf_hl(
    _state.ui.buf,
    _state.ns,
    "Comment",
    1,
    hint_byte,
    hint_byte + #hint
  )
  ui_utils.buf_hl(_state.ui.buf, _state.ns, "Comment", 3, 0, -1)

  for lnum, entry in pairs(_state.ui.line_map) do
    local icon_hl = entry.kind == "ft_group" and "Title"
      or entry.kind == "detail" and "Comment"
      or state_mod.is_enabled(category, entry.name) and "DiagnosticOk"
      or "Comment"
    ui_utils.buf_hl(
      _state.ui.buf,
      _state.ns,
      icon_hl,
      lnum - 1,
      entry.icon_byte,
      entry.icon_byte + 3
    )
    ui_utils.buf_hl(
      _state.ui.buf,
      _state.ns,
      entry.status_hl,
      lnum - 1,
      entry.status_byte,
      -1
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
  local sep = string.rep("─", win_width - 4)

  local lines = {}
  local section_lnums = {}

  local function render_section(title)
    table.insert(lines, ui_utils.fill_line("", win_width))
    table.insert(lines, ui_utils.fill_line("  " .. title, win_width))
    section_lnums[#lines] = true
  end

  local function row(key, desc)
    table.insert(
      lines,
      ui_utils.fill_line(string.format("  %-18s %s", key, desc), win_width)
    )
  end

  table.insert(lines, ui_utils.fill_line("", win_width))
  table.insert(lines, ui_utils.fill_line("  ? Help", win_width))
  table.insert(lines, ui_utils.fill_line("  " .. sep, win_width))

  render_section("Navigation")
  row("1-4", "Switch tab  LSP / DAP / LINTER / FORMATTER")
  row("<Tab>", "Next tab")
  row("<S-Tab>", "Previous tab")

  render_section("Actions")
  row("<Space>", "Toggle enable / disable")
  row("<CR> / o / za", "Expand / collapse details")
  row("i", "Install mason package")
  row("[ / ]", "Reorder expanded ft detail (LINTER / FORMATTER only)")
  row("K", "Show full details (all tabs)")

  render_section("General")
  row("g?", "Toggle this help page")
  row("q / <Esc>", "Close Service Manager")

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
