local configs = require("config")
local borders = require("config.borders")

---@type snacks.Config
return {
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
  statuscolumn = {
    enabled = true,

    -- priority of signs on the left (high to low)
    left = { "mark", "sign" },
    right = { "fold", "git" },

    folds = {
      open = true, -- show open fold icons
      git_hl = false, -- use Git Signs hl for fold icons
    },
    git = {
      -- patterns to match Git signs
      patterns = { "GitSign", "MiniDiffSign" },
    },
    refresh = 50, -- refresh at most every 50ms
  },
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
            -- title = "Select {title}",
            title = "{title}",
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
}
