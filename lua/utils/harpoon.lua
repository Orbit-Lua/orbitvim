local M = {}

local fs = require("utils.fs")
local highlights = require("utils.hl")
local icons = require("utils.icons")

local harpoon_ns = vim.api.nvim_create_namespace("harpoon")

M.short_path_length = 8

---@param path string
---@return string
M.format_display = function(path)
  local icon = icons.get_file_icon(path)
  return "  " .. icon .. " " .. path
end

---Returns a harpoon extension table that highlights the current file entry.
---@return table harpoon extension spec
M.highlight_current_file = function()
  return {
    UI_CREATE = function(cx)
      for line_number, name_of_harpoon in pairs(cx.contents) do
        if line_number == 1 and name_of_harpoon == "" then
          break
        end

        local short_path = fs.pretty_path(
          cx.current_file,
          { length = M.short_path_length, only_cwd = true }
        )

        if short_path == "" then
          return
        end

        local format_path = M.format_display(short_path)
        name_of_harpoon = string.gsub(name_of_harpoon, "([%-%[%]])", "%%%1")
        if string.find(format_path, name_of_harpoon) then
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
          vim.api.nvim_win_set_cursor(cx.win_id, { line_number, 0 })
        end
      end
    end,
  }
end

return M
