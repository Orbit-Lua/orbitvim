local M = {}

local fs = require("utils.fs")
local highlights = require("utils.hl")
local icons = require("utils.icons")

local harpoon_ns = vim.api.nvim_create_namespace("harpoon")

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

        local short_path = fs.pretty_path(cx.current_file, {
          length = require("config.navigation").short_path_length,
          only_cwd = true,
        })

        if short_path == "" then
          return
        end

        local format_path = M.format_display(short_path)
        if string.find(format_path, name_of_harpoon, 1, true) then
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

function M.create_list_item(config, value)
  value = value
    or fs.plenary_make_relative_path(
      vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()),
      config.get_root_dir()
    )

  local bufnr = vim.fn.bufnr(value, false)
  local pos = { 1, 0 }
  if bufnr ~= -1 then
    pos = vim.api.nvim_win_get_cursor(0)
  end

  return {
    value = value,
    context = {
      row = pos[1],
      col = pos[2],
      short_path = fs.pretty_path(value, {
        length = require("config.navigation").short_path_length,
        only_cwd = true,
      }),
    },
  }
end

function M.setup(opts)
  local harpoon = require("harpoon")

  harpoon:setup(opts)

  -- this will set cursor to current file
  harpoon:extend(M.highlight_current_file())

  vim.keymap.set("n", "<leader>ba", function()
    harpoon:list():add()
  end, { desc = "add buffer to harpoon" })

  -- Toggle previous & next buffers stored within Harpoon list
  vim.keymap.set("n", "<M-S-p>", function()
    harpoon:list():prev()
  end, { desc = "harpoon previous item" })

  vim.keymap.set("n", "<M-S-n>", function()
    harpoon:list():next()
  end, { desc = "harpoon next item" })

  vim.keymap.set("n", "<C-e>", function()
    harpoon.ui:toggle_quick_menu(harpoon:list())
  end)
end

return M
