local ok, err = pcall(function()
  dofile(vim.g.base46_cache .. "git")
end)
if not ok then
  vim.notify("[theme] " .. tostring(err), vim.log.levels.WARN)
end

local configs = require("config")

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
