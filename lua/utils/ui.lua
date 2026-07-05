local M = {}

local harpoon = require("utils.harpoon")
local highlights = require("utils.hl")
local icons = require("utils.icons")
local str = require("utils.str")
local term = require("utils.term")
local tree = require("utils.tree")
local window = require("utils.window")

M.harpoon = harpoon

M.get_neo_tree_width = tree.get_neo_tree_width
M.tree_offset = tree.offset

M.get_text_offset = window.get_text_offset
M.win_is_floating = window.is_floating
M.get_editor_win = window.get_editor_win
M.get_completion_window_size = window.get_completion_size
M.get_doc_window_size = window.get_doc_size

M.get_file_icon = icons.get_file_icon

M.trunc = str.trunc
M.rpad = str.rpad
M.fill_line = str.fill_line

M.buf_hl = highlights.buf_hl
M.check_toggle_term = term.can_toggle

M.close_lazy_view = function()
  return require("config.startup").close_lazy_view()
end

M.load_options = function()
  return require("config.startup").load_options()
end

M.load_base46_cache = function(name)
  return require("config.theme").load_cache(name)
end

return M
