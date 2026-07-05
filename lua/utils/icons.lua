local M = {}

---@param path string
---@param opts? {colored?: boolean}
---@return string
M.get_file_icon = function(path, opts)
  opts = opts or {}

  local web_devicons_present, web_devicons = pcall(require, "nvim-web-devicons")
  if not web_devicons_present then
    return ""
  end

  local filename = vim.fn.fnamemodify(path, ":t")
  local icon = "󰈚 "
  local devicon
  local devicon_hl_name = ""

  if filename ~= "" then
    devicon, devicon_hl_name =
      web_devicons.get_icon(filename, filename:match("%.([^%.]+)$"))
    icon = devicon or ""
  end

  if opts.colored then
    icon = string.format("%%#%s#", devicon_hl_name) .. icon .. "%*"
  end

  return icon
end

return M
