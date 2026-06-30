local M = {}

M.packages = require("config.packages")

M.icons = {
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
    Copilot = " ",
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
  },
}

return M
