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

local function get_web_devicon(path)
  local web_devicons_present, web_devicons = pcall(require, "nvim-web-devicons")
  if not web_devicons_present then
    return nil, nil
  end

  local filename = vim.fn.fnamemodify(path, ":t")
  if filename == "" then
    return nil, nil
  end

  return web_devicons.get_icon(
    filename,
    filename:match("%.([^%.]+)$"),
    { default = true }
  )
end

---@param path string
---@param opts? {colored?: boolean}
---@return string
M.get_file_icon = function(path, opts)
  opts = opts or {}

  local icon, icon_hl_name = get_mini_icon(path)

  if icon == nil or icon == "" then
    icon, icon_hl_name = get_web_devicon(path)
  end

  return format_icon(icon, icon_hl_name, opts.colored)
end

M.get_file_icons = M.get_file_icon

return M
