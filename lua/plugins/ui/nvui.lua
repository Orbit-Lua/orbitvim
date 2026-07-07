local function hl_has_fg(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and hl.fg ~= nil
end

local function ensure_icon_hl_fallbacks()
  local ok, devicon_default =
    pcall(vim.api.nvim_get_hl, 0, { name = "DevIconDefault", link = false })
  local fallback = ok
      and devicon_default.fg ~= nil
      and { fg = devicon_default.fg }
    or { link = "Normal" }

  for _, name in ipairs({
    "MiniIconsAzure",
    "MiniIconsBlue",
    "MiniIconsCyan",
    "MiniIconsGreen",
    "MiniIconsGrey",
    "MiniIconsOrange",
    "MiniIconsPurple",
    "MiniIconsRed",
    "MiniIconsYellow",
  }) do
    if not hl_has_fg(name) then
      vim.api.nvim_set_hl(0, name, fallback)
    end
  end
end

---@type LazySpec[]
return {
  {
    "Orbit-Lua/nv-base46",
    build = function()
      require("base46").load_all_highlights()
    end,
  },

  {
    "Orbit-Lua/nv-ui",
    lazy = false,
    config = function()
      require("nvchad")
    end,
  },

  {
    "nvim-mini/mini.icons",
    lazy = false,
    opts = {},
    config = function(_, opts)
      local mini_icons = require("mini.icons")
      mini_icons.setup(opts)
      ensure_icon_hl_fallbacks()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("OrbitMiniIconFallbacks", {
          clear = true,
        }),
        callback = ensure_icon_hl_fallbacks,
      })
      _G.MiniIcons.mock_nvim_web_devicons()
    end,
  },

  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    cond = false,
    opts = function()
      require("config.theme").load_cache("devicons")
      return { override = require("nvchad.icons.devicons") }
    end,
  },
}
