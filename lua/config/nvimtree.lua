local icons = require("config.icons")
local is_windows = require("utils.os").is_win()

---@type nvim_tree.config
return {
  -- Windows event storms can disable watchers; refresh on tree entry instead.
  filesystem_watchers = { enable = not is_windows },
  auto_reload_on_write = true,
  reload_on_bufenter = is_windows,
  filters = { dotfiles = false },
  disable_netrw = true,
  hijack_cursor = true,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = {
      enable = false,
    },
  },
  view = {
    width = 40,
    preserve_window_proportions = true,
    signcolumn = "no",
  },
  renderer = {
    root_folder_label = false,
    highlight_git = "all",
    highlight_diagnostics = "all",
    indent_markers = { enable = true },
    icons = {
      glyphs = {
        default = icons.fs.default,
        folder = icons.fs.folder,
        git = {
          unstaged = icons.git.unstaged,
          staged = icons.git.staged,
          unmerged = icons.git.unmerged,
        },
      },
      diagnostics_placement = "right_align",
    },
  },
  diagnostics = {
    enable = true,
    icons = icons.diagnostics,
  },
  git = {
    enable = false,
    timeout = 200,
  },
}
