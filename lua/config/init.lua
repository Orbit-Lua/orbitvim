local M = {}

M.packages = require("config.packages")

M.icons = {
  formatter = {
    error = "✖",
    success = "✔",
  },

  mason = {
    package_pending = " ",
    package_installed = " ",
    package_uninstalled = " ",
  },

  misc = {
    dots = "󰇘",
  },

  -- spec: { icon, hl_group, line_hl_group, num_hl_group }
  -- https://github.com/mfussenegger/nvim-dap/blob/531771530d4f82ad2d21e436e3cc052d68d7aebb/doc/dap.txt#L450
  dap = {
    Stopped = { "󰁕 ", "DiagnosticWarn", "DiagnosticVirtualTextWarn" },
    Breakpoint = { "●", "DapBreakpointColor" },
    BreakpointCondition = { " " },
    BreakpointRejected = { " ", "DiagnosticError" },
    LogPoint = { ".>" },
  },

  diagnostics = {
    error = " ",
    warning = " ",
    hint = " ",
    info = " ",
  },
  git = {
    added = " ",
    modified = " ",
    removed = " ",
    unstaged = "󰄱",
    staged = "󰱒",
    unmerged = "",
  },
  fs = {
    default = "󰈚",
    folder = {
      default = "",
      empty = "",
      empty_open = "",
      open = "",
      symlink = "",
    },
  },

  -- refer to:
  -- https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance
  kinds = {
    Array = " ",
    Boolean = "󰨙 ",
    Class = " ",
    Codeium = "󰘦 ",
    Color = " ",
    Control = " ",
    Collapsed = " ",
    Constant = "󰏿 ",
    Constructor = " ",
    Minuet = " ",
    Enum = " ",
    EnumMember = " ",
    Event = " ",
    Field = " ",
    File = " ",
    Folder = " ",
    Function = "󰊕 ",
    Interface = " ",
    Key = " ",
    Keyword = " ",
    Method = "󰊕 ",
    Module = " ",
    Namespace = "󰦮 ",
    Null = " ",
    Number = "󰎠 ",
    Object = " ",
    Operator = " ",
    Package = " ",
    Property = " ",
    Reference = " ",
    Snippet = "󱄽 ",
    String = " ",
    Struct = "󰆼 ",
    Supermaven = " ",
    TabNine = "󰏚 ",
    Text = " ",
    TypeParameter = " ",
    Unit = " ",
    Value = " ",
    Variable = "󰀫 ",
  },

  separators = {
    default = { left = "", right = "" },
    round = { left = "", right = "" },
    block = { left = "█", right = "█" },
    arrow = { left = "", right = "" },
  },
}

M.message_ignored = {
  lsp = {
    -- "is not accessed",
    -- "Unused local",
  },

  notify = {
    "man.lua",
    "roslyn: %-32000",
    "roslyn: %-30099",
    "lua_ls: %-32603",
  },

  msg_show = {
    "; after #%d+",
    "; before #%d+",

    "%d+L, %d+B",
    "%d+ fewer lines",
    "%d+ more lines",
    "%d+ lines yanked",
    "%d+ lines moved",
    "%d+ lines [><]ed%s+%d+ time",

    "Error INVALID_SERVER_MESSAGE: nil",
    "snacks/util/init.lua:207: Invalid window id",
  },

  progress = {
    "Searching in files",
  },
}

return M
