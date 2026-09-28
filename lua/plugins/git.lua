local icons = require("config.icons")

---@type LazySpec[]
return {
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    init = function()
      require("core.theme").load_cache("git")
    end,
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
        add = { text = icons.git.added },
        change = { text = icons.git.modified },
        delete = { text = icons.git.removed },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
    },
  },
}
