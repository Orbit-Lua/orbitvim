---@module "ui"

local config = require("config")
local borders = require("config.borders")

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "tokyonight",
  theme_toggle = { "tokyonight", "vscode_light" },
  hl_override = {
    ["@comment"] = { italic = true },
    ["@comment.todo"] = { bg = "green" },
    Comment = { italic = true },
    IblChar = { fg = "grey" },
    IblScopeChar = { fg = "purple" },
    NvimTreeOpenedFolderName = { fg = "green", bold = true },
    TreesitterContext = { link = "CursorLine" },
    LspInlayHint = { fg = "#808080", bg = "one_bg", italic = true },
    DevIconDefault = { fg = "white" },
    NormalFloat = { bg = "black" },
    FloatBorder = { fg = "blue" },
    FloatTitle = { fg = "blue", bg = "black" },
  },
  hl_add = {
    active_context = { fg = "blue" },
    CmpGhostText = { link = "Comment", default = true },
    DapBreakpointColor = { fg = "red" },
    MiniIconsGrey = { link = "DevIconDefault" },
    NoiceCmdlineIcon = { fg = "purple" },
    NoiceCmdlinePopupBorder = { fg = "green" },
    NoiceCmdlinePopup = { bg = "black" },
    NoiceMini = { bg = "black" },
    NoiceCmdlinePopupBorderSearch = { fg = "yellow" },
    NoiceCmdlinePopupTitle = { fg = "blue" },
    NoicePopupBorder = { fg = "blue" },
    SnacksLazygitActiveBorder = { fg = "purple", bold = true },
    SnacksPickerMatch = { fg = "green", bold = true, bg = "NONE" },
    SnacksPickerDir = { fg = "blue" },
    SnacksPickerPathHidden = { fg = "blue" },
  },
  excluded = {},
  changed_themes = {},
  transparency = false,
}

M.nvdash = { load_on_startup = false, header = {}, buttons = {} }
M.term = {
  float = {
    relative = "editor",
    row = 0.1,
    col = 0.1,
    width = 0.8,
    height = 0.8,
    border = borders.default,
  },
  startinsert = true,
  base46_colors = true,
  winopts = { number = false, relativenumber = false },
  sizes = { sp = 0.3, vsp = 0.2, ["bo sp"] = 0.3, ["bo vsp"] = 0.2 },
}
M.lsp = { signature = false }
M.ui = {
  statusline = {
    enabled = true,
    theme = "default",
    separator_style = "round",
    show_lsp_msg = false,
    order = nil,
    modules = nil,
    truncation_length = 3,
  },
  tabufline = {
    enabled = true,
    lazyload = false,
    treeOffsetFt = "NvimTree",
    modules = nil,
    bufwidth = 21,
    order = { "treeOffset", "buffers" },
  },
  cmp = {
    icons_left = false,
    style = "default",
    abbr_maxwidth = 60,
    format_colors = { lsp = true, icon = "󱓻" },
  },
  telescope = { style = "borderless" },
}
M.cheatsheet = {
  theme = "grid",
  excluded_groups = { "terminal (t)", "autopairs", "Nvim", "Opens" },
}
M.mason = { skip = {}, pkgs = config.packages.mason_ensure_installed }
M.colorify = {
  enabled = true,
  mode = "virtual",
  virt_text = "󱓻 ",
  highlight = { hex = true, lspvars = true },
}

return M
