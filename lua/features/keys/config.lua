local borders = require("shared.borders")

return {
  ---@type false | "classic" | "modern" | "helix"
  preset = "helix",
  win = {
    border = borders.default,
  },
  spec = {
    { "<leader>b", group = "buffer" },
    { "<leader>c", group = "code" },
    { "<leader>d", group = "debug" },
    { "<leader>f", group = "file/find" },
    { "<leader>g", group = "git" },
    { "<leader>m", group = "markdown" },
    { "<leader>s", group = "search" },
    { "<leader>t", group = "trouble/diagnostic" },
    { "<leader>u", group = "ui" },
    { "<leader>w", group = "whichkey" },
  },
}
