local configs = require("config")
local theme = require("config.theme")

theme.load_cache("git")

---@type LazySpec[]
return {
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = configs.icons.git.added },
        change = { text = configs.icons.git.modified },
        delete = { text = configs.icons.git.removed },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
    },
  },
}
