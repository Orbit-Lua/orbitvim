local icons = require("shared.icons")

return {
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
}
