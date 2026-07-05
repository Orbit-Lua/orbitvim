local M = {}

local str = require("utils.str")

---@class Service.Table.Column
---@field key string
---@field label string
---@field width integer?
---@field grow boolean?

---@class Service.Table.Row
---@field cells table<string, string>
---@field entry Service.Entry?
---@field icon_cell string?

---@class Service.Table.RenderOpts
---@field columns Service.Table.Column[]
---@field rows Service.Table.Row[]
---@field width integer
---@field indent integer?
---@field separator string?
---@field cell_padding integer?

---@class Service.Table.CellRange
---@field start_col integer
---@field end_col integer

---@param columns Service.Table.Column[]
---@param width integer
---@param indent integer
---@param separator string
---@return table<string, integer>
local function resolve_widths(columns, width, indent, separator)
  local widths = {}
  local fixed_width = indent + (#columns - 1) * #separator
  local grow_count = 0

  for _, column in ipairs(columns) do
    if column.grow then
      grow_count = grow_count + 1
    else
      widths[column.key] = column.width or 0
      fixed_width = fixed_width + widths[column.key]
    end
  end

  local grow_width = math.max(1, width - fixed_width)
  if grow_count > 0 then
    grow_width = math.max(1, math.floor(grow_width / grow_count))
  end

  for _, column in ipairs(columns) do
    if column.grow then
      widths[column.key] = grow_width
    end
  end

  return widths
end

---@param width integer
---@param cell_padding integer
---@return integer
local function padding_for_width(width, cell_padding)
  local pad = math.max(0, math.min(cell_padding, math.floor((width - 1) / 2)))
  return pad
end

---@param value string
---@param width integer
---@param cell_padding integer
---@return string cell, integer content_start, integer content_end
local function fit_cell(value, width, cell_padding)
  local pad = padding_for_width(width, cell_padding)
  local inner_w = math.max(1, width - (pad * 2))
  local fitted = str.trunc(value or "", inner_w)
  local text = str.rpad(fitted, inner_w)
  return string.rep(" ", pad) .. text .. string.rep(" ", pad),
    pad,
    pad + #fitted
end

---@param columns Service.Table.Column[]
---@param widths table<string, integer>
---@param indent integer
---@param separator string
---@param cell_padding integer
---@param cells table<string, string>
---@return string line, table<string, Service.Table.CellRange> cell_ranges
local function build_line(
  columns,
  widths,
  indent,
  separator,
  cell_padding,
  cells
)
  local line = string.rep(" ", indent)
  local cell_ranges = {}

  for i, column in ipairs(columns) do
    if i > 1 then
      line = line .. separator
    end
    local cell, content_start, content_end =
      fit_cell(cells[column.key] or "", widths[column.key], cell_padding)
    cell_ranges[column.key] = {
      start_col = #line + content_start,
      end_col = #line + content_end,
    }
    line = line .. cell
  end

  return line, cell_ranges
end

---@param opts Service.Table.RenderOpts
---@return string header, string[] lines, table<integer, Service.Entry>
function M.render(opts)
  local indent = opts.indent or 0
  local separator = opts.separator or "  "
  local cell_padding = math.max(0, opts.cell_padding or 0)
  local widths = resolve_widths(opts.columns, opts.width, indent, separator)

  local header_cells = {}
  for _, column in ipairs(opts.columns) do
    header_cells[column.key] = column.label
  end
  local header = build_line(
    opts.columns,
    widths,
    indent,
    separator,
    cell_padding,
    header_cells
  )
  header = str.fill_line(header, opts.width)

  local lines = {}
  local line_map = {}
  for _, row in ipairs(opts.rows) do
    local line, cell_ranges = build_line(
      opts.columns,
      widths,
      indent,
      separator,
      cell_padding,
      row.cells
    )
    table.insert(lines, str.fill_line(line, opts.width))

    if row.entry then
      local entry = vim.tbl_extend("force", {}, row.entry)
      local tree_range = cell_ranges.tree
      local icon_range = cell_ranges[row.icon_cell or "icon"]
      local status_range = cell_ranges.status
      if tree_range then
        entry.tree_byte = tree_range.start_col
        entry.tree_end_byte = tree_range.end_col
      end
      if icon_range then
        entry.icon_byte = icon_range.start_col
        entry.icon_end_byte = icon_range.end_col
      end
      if status_range then
        entry.status_byte = status_range.start_col
        entry.status_end_byte = status_range.end_col
      else
        entry.status_byte = #line
        entry.status_end_byte = #line
      end
      line_map[#lines] = entry
    end
  end

  return header, lines, line_map
end

---@param text string
---@param width integer
---@param prefix? string
---@return string
function M.empty_line(text, width, prefix)
  return str.fill_line((prefix or "  ") .. text, width)
end

return M
