local M = {}

local function format_icon(icon, hl_name, colored)
  if icon == nil or icon == "" then
    return ""
  end

  if colored and hl_name ~= nil and hl_name ~= "" then
    return string.format("%%#%s#", hl_name) .. icon .. "%*"
  end

  return icon
end

local function get_mini_icon(path)
  local mini_icons_present, mini_icons = pcall(require, "mini.icons")
  if not mini_icons_present then
    return nil, nil
  end

  if _G.MiniIcons == nil then
    mini_icons.setup()
  end

  return mini_icons.get("file", path)
end

---@param path string
---@param opts? {colored?: boolean}
---@return string
M.get_file_icon = function(path, opts)
  opts = opts or {}

  local icon, icon_hl_name = get_mini_icon(path)

  return format_icon(icon, icon_hl_name, opts.colored)
end

return M
