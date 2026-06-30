local M = {}

local fs = require("utils.fs")
local highlights = require("utils.hl")

local CONFIG = {
  completion = { max_w = 60, max_h = 15, pct_w = 0.4, pct_h = 0.3 },
  doc = { max_w = 80, max_h = 20, pct_w = 0.5, pct_h = 0.4 },
}

local harpoon_ns = vim.api.nvim_create_namespace("harpoon")

M.harpoon = {}

---@return integer width of the neo-tree window, or 0 if not open
M.get_neo_tree_width = function()
  local winid = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if bufname:match("neo%-tree filesystem") or bufname:match("neo%-tree") then
      winid = win
      break
    end
  end

  if winid then
    return vim.api.nvim_win_get_width(winid)
  else
    return 0
  end
end

---@return string statusline segment with neo-tree offset padding, or empty string
M.tree_offset = function()
  local w = M.get_neo_tree_width()
  return w == 0 and ""
    or "%#NeoTreeNormal#"
      .. string.rep(" ", w)
      .. "%#NeoTreeWinSeparator#"
      .. "│"
end

M.harpoon.short_path_length = 8

---@param path string
---@return string
M.harpoon.format_display = function(path)
  local icon = M.get_file_icon(path)
  return "  " .. icon .. " " .. path
end

---Returns a harpoon extension table that highlights the current file entry.
---@return table harpoon extension spec
M.harpoon.highlight_current_file = function()
  return {
    UI_CREATE = function(cx)
      for line_number, name_of_harpoon in pairs(cx.contents) do
        if line_number == 1 and name_of_harpoon == "" then
          break
        end

        local short_path = fs.pretty_path(
          cx.current_file,
          { length = M.harpoon.short_path_length, only_cwd = true }
        )

        if short_path == "" then
          return
        end

        local format_path = M.harpoon.format_display(short_path)
        -- name_of_harpoon = string.gsub(name_of_harpoon, "%-", "%%-")
        name_of_harpoon = string.gsub(name_of_harpoon, "([%-%[%]])", "%%%1")
        if string.find(format_path, name_of_harpoon) then
          -- highlight the harpoon menu line that corresponds to the current buffer
          local line = vim.api.nvim_buf_get_lines(
            cx.bufnr,
            line_number - 1,
            line_number,
            false
          )[1]

          vim.api.nvim_buf_set_extmark(
            cx.bufnr,
            harpoon_ns,
            line_number - 1,
            2,
            {
              end_col = #line,
              hl_group = highlights.util.get_hl_name_without_syntax(
                highlights.hl_groups.active_context
              ),
            }
          )
          -- set the position of the cursor in the harpoon menu to the start of the current buffer line
          vim.api.nvim_win_set_cursor(cx.win_id, { line_number, 0 })
        end
      end
    end,
  }
end

---@param win_id integer
---@return integer
M.get_text_offset = function(win_id)
  return vim.fn.getwininfo(win_id)[1].textoff
end

---@param path string
---@param opts? {colored?: boolean}
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
    icon = (devicon or "")
  end

  if opts.colored then
    icon = string.format("%%#%s#", devicon_hl_name) .. icon .. "%*"
  end

  return icon
end

---@param s string
---@param max_w integer
---@return string
M.trunc = function(s, max_w)
  local ellipsis = "…"
  if vim.fn.strdisplaywidth(s) <= max_w then
    return s
  end
  local ew = vim.fn.strdisplaywidth(ellipsis)
  return s:sub(1, max_w - ew) .. ellipsis
end

---@param s string
---@param w integer
---@return string
M.rpad = function(s, w)
  local dw = vim.fn.strdisplaywidth(s)
  return dw < w and (s .. string.rep(" ", w - dw)) or s
end

---Pad `s` with trailing spaces to fill `inner_w` display columns.
---Ensures cursorline highlight extends to the right edge of the window.
---@param s string
---@param inner_w integer
---@return string
M.fill_line = function(s, inner_w)
  local dw = vim.fn.strdisplaywidth(s)
  return dw < inner_w and (s .. string.rep(" ", inner_w - dw)) or s
end

---Set an extmark highlight on a buffer range. Replaces deprecated nvim_buf_add_highlight.
---Pass end_col = -1 to highlight to end of line (uses byte length of the line).
---@param buf integer
---@param ns_id integer
---@param hl_group string
---@param row integer 0-indexed row
---@param start_col integer byte column
---@param end_col integer byte column, or -1 for end of line
M.buf_hl = function(buf, ns_id, hl_group, row, start_col, end_col)
  if end_col == -1 then
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
    end_col = #line
  end
  if end_col <= start_col then
    return
  end
  vim.api.nvim_buf_set_extmark(buf, ns_id, row, start_col, {
    end_col = end_col,
    hl_group = hl_group,
  })
end

---@return boolean true when toggling a managed terminal is safe
M.check_toggle_term = function()
  local current_ft = vim.bo.filetype

  if current_ft:match("Term_") or not M.win_is_floating() then
    return true
  end

  return false
end

---@param winid? integer
---@return boolean
M.win_is_floating = function(winid)
  winid = winid or 0
  local cfg = vim.api.nvim_win_get_config(winid)
  return cfg.relative ~= ""
end

---@return integer, integer
M.get_completion_window_size = function()
  local max_width = math.min(
    CONFIG.completion.max_w,
    math.floor(vim.o.columns * CONFIG.completion.pct_w)
  )
  local max_height = math.min(
    CONFIG.completion.max_h,
    math.floor(vim.o.lines * CONFIG.completion.pct_h)
  )
  return max_width, max_height
end

---@return integer, integer
M.get_doc_window_size = function()
  local max_width =
    math.min(CONFIG.doc.max_w, math.floor(vim.o.columns * CONFIG.doc.pct_w))
  local max_height =
    math.min(CONFIG.doc.max_h, math.floor(vim.o.lines * CONFIG.doc.pct_h))
  return max_width, max_height
end

M.get_editor_win = function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      return win
    end
  end
end

M.loader = function()
  local defaults_ok, _ = pcall(require, "config.defaults")
  local config_options_ok, _ = pcall(require, "config.options")

  if not defaults_ok or not config_options_ok then
    vim.notify(
      "Failed to load options. Please check your configuration.",
      vim.log.levels.ERROR
    )
  end
end

M.load_options = function()
  local win = M.get_editor_win()

  if win and win ~= vim.api.nvim_get_current_win() then
    vim.api.nvim_win_call(win, M.loader)
  else
    M.loader()
  end
end

M.close_lazy_view = function()
  local ok, lazy_view = pcall(require, "lazy.view")

  if ok and lazy_view.visible() and lazy_view.view then
    lazy_view.view:close()
  end
end

M.load_base46_cache = function(name)
  local ok, err = pcall(function()
    dofile(vim.g.base46_cache .. name)
  end)
  if not ok then
    vim.notify("[theme] " .. tostring(err), vim.log.levels.WARN)
  end
end

return M
