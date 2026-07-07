---@class BordersConfig
local M = {}

-- Default border for standard float windows (cmp, lsp, trouble, which-key, service, term).
M.default = "rounded"

-- Box-drawing border with CmpBorder highlight (LSP diagnostic float).
M.lsp_diagnostic = {
  { "┌", "CmpBorder" },
  { "─", "CmpBorder" },
  { "┐", "CmpBorder" },
  { "│", "CmpBorder" },
  { "┘", "CmpBorder" },
  { "─", "CmpBorder" },
  { "└", "CmpBorder" },
  { "│", "CmpBorder" },
}

-- Noice uses nui.nvim { style = "..." } format for popup views.
M.noice = {
  cmdline = { style = "rounded" },
}

M.lsp = {
  hover = "single",
  signature_help = "single",
}

M.cmp = {
  window = {
    completion = "single",
    documentation = "single",
  },
}

-- Snacks style overrides and picker layout borders.
M.snacks = {
  style = "rounded",
  picker = {
    default = {
      box = "none",
      preview = "rounded",
      input = "rounded",
      list = "rounded",
    },
    select = {
      box = "none",
      input = "rounded",
      list = "rounded",
    },
    vscode = {
      box = "none",
      input = "rounded",
      list = "hpad",
      preview = true,
    },
    vertical = {
      box = "rounded",
      input = "bottom",
      list = "none",
      preview = "top",
    },
  },
}

return M
