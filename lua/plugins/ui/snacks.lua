local configs = require("config")
local borders = require("config.borders")

-- https://github.com/folke/snacks.nvim?tab=readme-ov-file#-features
---@type LazySpec[]
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,

    ---@type snacks.Config
    opts = {
      -- current not used
      -- snacks.git
      -- snacks.keymap
      -- snacks.toggle
      -- snacks.scratch
      -- snacks.util
      -- snacks.win
      dim = {},
      gh = {},
      gitbrowse = {},
      zen = {},

      -- current in use
      -- snacks.notify
      -- snacks.rename
      animate = {},
      bigfile = { enabled = true },
      explorer = { enabled = false },
      image = { enabled = true },
      indent = { enabled = true },
      input = {
        enabled = true,
        icon = " ",
      },
      lazygit = {},
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscomn = { enabled = true },
      words = { enabled = true },

      -- reference: https://github.com/folke/snacks.nvim/discussions/111#discussioncomment-11986334
      dashboard = {
        enabled = true,
        preset = {
          header = require("plugins.ui.header").claude_snack,
        },

        -- built-in sections: https://github.com/folke/snacks.nvim/blob/main/docs/dashboard.md#-features
        sections = {
          { section = "header", align = "center" },
          { pane = 2, section = "keys", gap = 1, padding = 1 },
          {
            pane = 2,
            title = "Recent Files",
            section = "recent_files",
            indent = 2,
            padding = { 1, 1 },
          },
          {
            pane = 2,
            title = "Projects",
            section = "projects",
            indent = 2,
            padding = 1,
          },
          { pane = 2, section = "startup" },
        },
      },

      notifier = {
        enabled = true,
        top_down = false,
        margin = { bottom = 2 },
        timeout = 3000,
        filter = function(notif)
          for _, msg in ipairs(configs.message_ignored.notify) do
            if notif.msg:find(msg) then
              return false
            end
          end
          return true
        end,
      },

      -- more config options refer to:
      -- https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
      picker = {
        enabled = true,

        sources = {
          files = {
            hidden = true,
          },
          grep = {
            hidden = true,
          },
        },

        win = {
          list = {
            wo = { wrap = false },
          },
          input = {
            keys = {
              ["<C-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
              ["<C-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
            },
          },
        },

        ---@type table<string, snacks.picker.layout.Config>
        layouts = {
          default = {
            layout = {
              backdrop = false,
              box = "horizontal",
              width = 0.87,
              height = 0.80,
              border = borders.snacks.picker.default.box,
              {
                box = "vertical",
                {
                  win = "list",
                  border = borders.snacks.picker.default.list,
                  flex = 1,
                },
                {
                  win = "input",
                  height = 1,
                  border = borders.snacks.picker.default.input,
                  title = "Find {title} {live} {flags}",
                },
              },
              {
                win = "preview",
                title = "Preview {preview}",
                border = borders.snacks.picker.default.preview,
                flex = 1,
                min_width = 30,
              },
            },
          },
          select = {
            layout = {
              backdrop = false,
              box = "vertical",
              border = borders.snacks.picker.select.box,
              width = 0.6,
              height = 0.4,
              {
                win = "input",
                height = 0.1,
                border = borders.snacks.picker.select.input,
                title = "Select {title}",
              },
              {
                win = "list",
                border = borders.snacks.picker.select.list,
                flex = 1,
              },
            },
          },
          vscode = {
            hidden = { "preview" },
            layout = {
              backdrop = false,
              row = 1,
              width = 0.4,
              min_width = 80,
              height = 0.4,
              border = borders.snacks.picker.vscode.box,
              box = "vertical",
              {
                win = "input",
                height = 1,
                border = borders.snacks.picker.vscode.input,
                title = "{title} {live} {flags}",
                title_pos = "center",
              },
              { win = "list", border = borders.snacks.picker.vscode.list },
              {
                win = "preview",
                title = "{preview}",
                border = borders.snacks.picker.vscode.preview,
              },
            },
          },
          vertical = {
            layout = {
              backdrop = false,
              width = 0.5,
              min_width = 80,
              height = 0.8,
              min_height = 30,
              box = "vertical",
              border = borders.snacks.picker.vertical.box,
              title = "{title} {live} {flags}",
              title_pos = "center",
              {
                win = "input",
                height = 1,
                border = borders.snacks.picker.vertical.input,
              },
              { win = "list", border = borders.snacks.picker.vertical.list },
              {
                win = "preview",
                title = "{preview}",
                height = 0.4,
                border = borders.snacks.picker.vertical.preview,
              },
            },
          },
        },
      },

      ---@type table<string, snacks.win.Config>
      styles = {
        notification = {
          border = borders.snacks.style,
        },
        input = {
          border = borders.snacks.style,
        },
      },
    },

    keys = {
      {
        "<leader>uD",
        function()
          require("snacks").dashboard()
        end,
        desc = "open dashboard",
      },
      {
        "<leader>un",
        function()
          require("snacks").picker.notifications()
        end,
        desc = "notification history",
      },

      -- find
      {
        "<leader>bd",
        function()
          require("snacks").bufdelete()
        end,
        desc = "close current buffer",
      },
      {
        "<leader>bb",
        function()
          require("snacks").picker.buffers()
        end,
        desc = "find buffers",
      },
      {
        "<leader>fc",
        function()
          require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "find config file",
      },
      {
        "<leader>ff",
        function()
          require("snacks").picker.files()
        end,
        desc = "find files",
      },
      {
        "<leader>fg",
        function()
          require("snacks").picker.git_files()
        end,
        desc = "find git files",
      },
      {
        "<leader>fp",
        function()
          require("snacks").picker.projects()
        end,
        desc = "find projects",
      },
      {
        "<leader>fr",
        function()
          require("snacks").picker.recent()
        end,
        desc = "find recent files",
      },

      -- git
      {
        "<leader>gb",
        function()
          require("snacks").picker.git_branches()
        end,
        desc = "git branches",
      },
      {
        "<leader>gl",
        function()
          require("snacks").picker.git_log()
        end,
        desc = "git log",
      },
      {
        "<leader>gL",
        function()
          require("snacks").picker.git_log_line()
        end,
        desc = "git log line",
      },
      {
        "<leader>gs",
        function()
          require("snacks").picker.git_status()
        end,
        desc = "git status",
      },
      {
        "<leader>gS",
        function()
          require("snacks").picker.git_stash()
        end,
        desc = "git stash",
      },
      {
        "<leader>gd",
        function()
          require("snacks").picker.git_diff()
        end,
        desc = "git diff (hunks)",
      },
      {
        "<leader>gf",
        function()
          require("snacks").picker.git_log_file()
        end,
        desc = "git log file",
      },

      -- grep
      {
        "<leader>sb",
        function()
          require("snacks").picker.lines()
        end,
        desc = "buffer lines",
      },
      {
        "<leader>sB",
        function()
          require("snacks").picker.grep_buffers()
        end,
        desc = "grep open buffers",
      },
      {
        "<leader>sg",
        function()
          require("snacks").picker.grep()
        end,
        desc = "grep files",
      },
      {
        "<leader>sw",
        function()
          require("snacks").picker.grep_word()
        end,
        desc = "grep selection or word",
        mode = { "n", "x" },
      },

      -- search
      {
        '<leader>s"',
        function()
          require("snacks").picker.registers()
        end,
        desc = "registers",
      },
      {
        "<leader>s/",
        function()
          require("snacks").picker.search_history()
        end,
        desc = "search history",
      },
      {
        "<leader>sa",
        function()
          require("snacks").picker.autocmds()
        end,
        desc = "autocmds",
      },
      {
        "<leader>sc",
        function()
          require("snacks").picker.command_history()
        end,
        desc = "command history",
      },
      {
        "<leader>sC",
        function()
          require("snacks").picker.commands()
        end,
        desc = "commands",
      },
      {
        "<leader>sd",
        function()
          require("snacks").picker.diagnostics()
        end,
        desc = "diagnostics",
      },
      {
        "<leader>sD",
        function()
          require("snacks").picker.diagnostics_buffer()
        end,
        desc = "buffer diagnostics",
      },
      {
        "<leader>sh",
        function()
          require("snacks").picker.highlights()
        end,
        desc = "highlights",
      },
      {
        "<leader>sH",
        function()
          require("snacks").picker.highlights({ pattern = "hl_group:^Snacks" })
        end,
        desc = "snack highlights",
      },
      {
        "<leader>si",
        function()
          require("snacks").picker.icons()
        end,
        desc = "icons",
      },
      {
        "<leader>sj",
        function()
          require("snacks").picker.jumps()
        end,
        desc = "jumps",
      },
      {
        "<leader>sk",
        function()
          require("snacks").picker.keymaps()
        end,
        desc = "keymaps",
      },
      {
        "<leader>sl",
        function()
          require("snacks").picker.loclist()
        end,
        desc = "location list",
      },
      {
        "<leader>s'",
        function()
          require("snacks").picker.marks()
        end,
        desc = "marks",
      },
      {
        "<leader>sM",
        function()
          require("snacks").picker.man()
        end,
        desc = "man pages",
      },
      {
        "<leader>sp",
        function()
          require("snacks").picker.lazy()
        end,
        desc = "search for plugin spec",
      },
      {
        "<leader>sq",
        function()
          require("snacks").picker.qflist()
        end,
        desc = "quickfix list",
      },
      {
        "<leader>sR",
        function()
          require("snacks").picker.resume()
        end,
        desc = "resume picker",
      },
      {
        "<leader>su",
        function()
          require("snacks").picker.undo()
        end,
        desc = "undo history",
      },

      -- other
      {
        "<leader>gg",
        function()
          require("snacks").lazygit()
        end,
        desc = "lazygit",
      },
    },

    config = function(_, opts)
      local snacks = require("snacks")
      local redraw_range = snacks.util.redraw_range

      -- Wrap to suppress invalid window id error popups
      snacks.util.redraw_range = function(...)
        pcall(redraw_range, ...)
      end

      snacks.setup(opts)
    end,
  },
}
