local theme = require("config.theme")
local icons = require("config").icons
local borders = require("config.borders")

theme.load_cache("nvimtree")

---@type LazySpec[]
return {
  {
    "stevearc/oil.nvim",
    event = "VeryLazy",
    cmd = "Oil",
    keys = {
      {
        "-",
        function()
          require("oil").toggle_float(nil, { preview = {} })
        end,
        desc = "oil toggle floating",
      },
    },
    opts = {
      default_file_explorer = false,
      delete_to_trash = true,
      keymaps = {
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-p>"] = false,
        ["-"] = false,
        ["`"] = false,
        ["s"] = { "<cmd>write<CR>", mode = "n", desc = "sync/apply changes" },
        ["R"] = "actions.refresh",
        ["H"] = "actions.toggle_hidden",
        ["."] = "actions.cd",
        ["<BS>"] = "actions.parent",
        [";"] = { ":", mode = "n", desc = "command mode" },
      },
      float = {
        max_width = 0.9,
        max_height = 0.9,
        border = borders.default,
        preview_split = "right",
      },
    },
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      filters = { dotfiles = false },
      disable_netrw = true,
      hijack_cursor = true,
      sync_root_with_cwd = true,
      update_focused_file = { enable = true, update_root = { enable = false } },
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
      diagnostics = { enable = true, icons = icons.diagnostics },
      git = { enable = false, timeout = 200 },
    },
    keys = {
      { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "nvimtree toggle window" },
      {
        "<leader>fe",
        "<cmd>NvimTreeFocus<CR>",
        desc = "nvimtree focus window",
      },
      {
        "<C-Right>",
        "<cmd>NvimTreeResize +5<CR>",
        desc = "nvimtree resize +5",
      },
      { "<C-Left>", "<cmd>NvimTreeResize -5<CR>", desc = "nvimtree resize -5" },
      {
        "<leader>fC",
        function()
          require("nvim-tree.api").fs.create()
        end,
        desc = "create file",
      },
    },
    config = function(_, opts)
      require("nvim-tree").setup(opts)
      local api = require("nvim-tree.api")
      api.events.subscribe(api.events.Event.FileCreated, function(_)
        vim.api.nvim_exec_autocmds("User", { pattern = "CreateFile" })
      end)
    end,
  },
}
