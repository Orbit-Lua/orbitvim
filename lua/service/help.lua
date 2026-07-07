local M = {}

local cfg = require("service.config")
local layout = require("service.layout")
local str = require("utils.str")

---@param lines string[]
---@param section_lnums table<integer, boolean>
---@param win_width integer
---@param title string
local function render_section(lines, section_lnums, win_width, title)
  layout.add_margin(lines, win_width)
  table.insert(lines, str.fill_line(cfg.layout.line_prefix .. title, win_width))
  section_lnums[#lines] = true
end

---@param lines string[]
---@param win_width integer
---@param key string
---@param desc string
local function render_row(lines, win_width, key, desc)
  table.insert(
    lines,
    str.fill_line(
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

---@param win_width integer
---@return string[] lines
---@return table<integer, boolean> section_lnums
function M.build(win_width)
  local sep = string.rep(
    cfg.layout.separator_char,
    win_width - cfg.layout.separator_inset
  )
  local lines = {}
  local section_lnums = {}

  table.insert(lines, str.fill_line("", win_width))
  table.insert(
    lines,
    str.fill_line(cfg.layout.line_prefix .. cfg.help.title, win_width)
  )
  table.insert(lines, str.fill_line(cfg.layout.line_prefix .. sep, win_width))

  for _, section in ipairs(cfg.help.sections) do
    render_section(lines, section_lnums, win_width, section.title)
    for _, help_row in ipairs(section.rows) do
      render_row(lines, win_width, help_row[1], help_row[2])
    end
  end

  return lines, section_lnums
end

return M
