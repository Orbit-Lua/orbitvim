local harpoon_utils = require("utils.harpoon")
local fs = require("utils.fs")
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

    ---@type oil.SetupOpts
    opts = {
      default_file_explorer = false,
      delete_to_trash = true,
      keymaps = {
        -- ["g."] = false,
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

  -- doc: https://github.com/nvim-tree/nvim-tree.lua
  {
    "nvim-tree/nvim-tree.lua",
    ---@type nvim_tree.config
    opts = {
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
        -- root_folder_label = function()
        --   return fs.new():get_cwd():pretty_path({ transform_home = true })
        -- end,
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
      {
        "<C-Left>",
        "<cmd>NvimTreeResize -5<CR>",
        desc = "nvimtree resize -5",
      },
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
      local Event = api.events.Event

      api.events.subscribe(Event.FileCreated, function(_)
        vim.api.nvim_exec_autocmds("User", { pattern = "CreateFile" })
      end)
    end,
  },

  {
    "Orbit-Lua/harpoon",
    -- "ThePrimeagen/harpoon",
    keys = {
      { "<C-e>", desc = "toggle harpoon quick menu" },
      { "<M-S-p>", desc = "harpoon previous item" },
      { "<M-S-n>", desc = "harpoon next item" },
      { "<leader>ba", desc = "add buffer to harpoon" },
    },
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    ---@type HarpoonPartialConfig
    opts = {
      -- https://github.com/ThePrimeagen/harpoon/blob/harpoon2/lua/harpoon/config.lua
      default = {
        -- refer to: https://github.com/ThePrimeagen/harpoon/issues/523#issuecomment-1984926994
        --
        create_list_item = function(config, value)
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
              short_path = fs.pretty_path(
                value,
                { length = harpoon_utils.short_path_length, only_cwd = true }
              ),
            },
          }
        end,

        display = function(list_item)
          local path = list_item.context.short_path or ""
          return harpoon_utils.format_display(path)
        end,
      },
    },
    ---@param opts HarpoonPartialConfig
    config = function(_, opts)
      local harpoon = require("harpoon")

      harpoon:setup(opts)

      -- this will set cursor to current file
      harpoon:extend(harpoon_utils.highlight_current_file())

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
    end,
  },
}
