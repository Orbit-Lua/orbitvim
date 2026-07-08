---@module "ui"

local config = require("config")
local borders = require("config.borders")

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "tokyonight",
  theme_toggle = { "tokyonight", "vscode_light" },

  -- Merged into ALL integrations (treesitter, lsp, cmp, etc.).
  -- Only affects EXISTING highlight groups, can NOT add new groups.
  -- Uses per-key merge, not full override.
  hl_override = {

    -- ------------------------------------------------------------------------- --
    -- ■ Editor                                                                  --
    -- ------------------------------------------------------------------------- --
    ["@comment"] = { italic = true },
    ["@comment.todo"] = {
      bg = "green",
    },
    Comment = { italic = true },
    IblChar = { fg = "grey" },
    IblScopeChar = { fg = "purple" },
    NvimTreeOpenedFolderName = { fg = "green", bold = true },
    TreesitterContext = { link = "CursorLine" },
    LspInlayHint = { fg = "#808080", bg = "one_bg", italic = true },

    -- icon hl fallback
    DevIconDefault = { fg = "white" },

    -- ------------------------------------------------------------------------- --
    -- ■ Window                                                                  --
    -- ------------------------------------------------------------------------- --
    NormalFloat = {
      bg = "black",
    },
    FloatBorder = { fg = "blue" },
    FloatTitle = { fg = "blue", bg = "black" },

    CmpPmenu = {
      bg = "black",
    },
    CmpBorder = {
      fg = "grey",
      bg = "NONE",
    },
    CmpDoc = {
      bg = "black",
    },
    CmpDocBorder = {
      fg = "grey",
      bg = "NONE",
    },
  },

  -- Merged into the "defaults" integration ONLY.
  -- CAN add new highlight groups (not limited to existing ones).
  -- Uses per-key merge, not full override.
  hl_add = {

    -- ------------------------------------------------------------------------- --
    -- ■ Misc                                                                    --
    -- ------------------------------------------------------------------------- --
    active_context = { fg = "blue" },
    CmpGhostText = { link = "Comment", default = true },
    DapBreakpointColor = { fg = "red" },
    ServiceMuted = { fg = "grey" },

    -- default icon hl
    MiniIconsGrey = { link = "DevIconDefault" },

    -- ------------------------------------------------------------------------- --
    -- ■ Noice.nvim                                                              --
    -- ------------------------------------------------------------------------- --
    NoiceCmdlineIcon = { fg = "purple" },
    NoiceCmdlinePopupBorder = { fg = "green" },
    NoiceCmdlinePopup = { bg = "black" },
    NoiceMini = { bg = "black" },
    NoiceCmdlinePopupBorderSearch = { fg = "yellow" },
    NoiceCmdlinePopupTitle = { fg = "blue" },
    NoicePopupBorder = { fg = "blue" },

    -- ------------------------------------------------------------------------- --
    -- ■ Snacks.nvim                                                             --
    -- ------------------------------------------------------------------------- --
    -- Snacks input
    -- SnacksInputPrompt = { fg = "purple" },
    -- SnacksInputBorder = { fg = "green" },
    -- SnacksInputTitle = { fg = "green" },

    -- Snacks picker
    SnacksPickerMatch = {
      fg = "green",
      bold = true,
      bg = "NONE",
    },
    SnacksPickerDir = { fg = "blue" },
    SnacksPickerPathHidden = { fg = "blue" },

    -- SnacksPickerBorder = { fg = "blue" },
    -- SnacksPickerInputBorder = { fg = "blue" },
    -- SnacksPickerPreviewBorder = { fg = "blue" },
    -- SnacksPickerListBorder = { fg = "blue" },
  },

  integrations = {},
  excluded = {},
  ---@diagnostic disable-next-line
  changed_themes = {},
  transparency = false,
}

M.nvdash = {
  load_on_startup = false,
  header = {},
  buttons = {},
}

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

-- use noice signature so disable nvchad signature
M.lsp = {
  signature = false,
}

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

    ---@type  ('"treeOffset"' | '"buffers"' | '"tabs"' | '"btns"')[]
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

M.mason = {
  skip = {},
  pkgs = config.packages.mason_ensure_installed,
}

M.colorify = {
  enabled = true,
  mode = "virtual",
  virt_text = "󱓻 ",
  highlight = { hex = true, lspvars = true },
}

return M
