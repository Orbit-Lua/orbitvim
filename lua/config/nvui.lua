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

    -- ------------------------------------------------------------------------- --
    -- ■ Telescope                                                               --
    -- ------------------------------------------------------------------------- --
    TelescopeMatching = {
      fg = "red",
      bg = "NONE",
    },

    TelescopeNormal = { link = "SnacksPickerList" },
    TelescopePromptNormal = { link = "SnacksPickerInput" },
    TelescopeSelection = { link = "SnacksPickerListCursorline" },

    TelescopePromptTitle = { link = "SnacksPickerInputTitle" },
    TelescopePromptPrefix = { link = "SnacksPickerPrompt" },
    TelescopePreviewTitle = { link = "SnacksPickerPreviewTitle" },

    TelescopeBorder = { link = "SnacksPickerBorder" },
    TelescopePromptBorder = { link = "SnacksPickerInputBorder" },
    TelescopeResultsTitle = { link = "SnacksPickerPreviewTitle" },

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
    SnacksPickerMatch = { link = "TelescopeMatching" },
    SnacksPickerDir = { fg = "blue" },
    SnacksPickerPathHidden = { fg = "grey_fg" },
    -- SnacksPickerDir = { fg = "#928374" },
    -- SnacksPickerPathHidden = { fg = "#928374" },

    --
    -- SnacksPickerInput = { link = "TelescopePromptNormal" },
    -- SnacksPickerList = { link = "TelescopeNormal" },
    -- SnacksPickerPreview = { link = "TelescopeNormal" },
    --
    -- SnacksPickerPrompt = { link = "TelescopePromptPrefix" },
    -- SnacksPickerInputTitle = { link = "TelescopePromptTitle" },
    -- SnacksPickerPreviewTitle = { link = "TelescopePreviewTitle" },
    --
    -- SnacksPickerBorder = { fg = "blue", bg = "black2" },
    -- SnacksPickerInputBorder = { fg = "blue", bg = "black2" },
    -- SnacksPickerPreviewBorder = { fg = "blue", bg = "darker_black" },
    -- SnacksPickerListBorder = { fg = "blue", bg = "darker_black" },
  },
}

M.nvdash = {
  load_on_startup = false,
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
}

-- use noice signature so disable nvchad signature
M.lsp = {
  signature = false,
}

M.ui = {
  statusline = {
    theme = "lucid",
    separator_style = "round",
    show_lsp_msg = false,
  },

  tabufline = {
    lazyload = false,
    ---@type  ('"treeOffset"' | '"buffers"' | '"tabs"' | '"btns"')[]
    order = { "treeOffset", "buffers" },
  },

  cmp = {
    style = "default",
  },
}

M.mason = {
  pkgs = config.packages.mason_ensure_installed,
}

return M
