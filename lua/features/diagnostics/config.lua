local borders = require("shared.borders")

return {
  trouble = {

    ---@type table<string, trouble.Mode>
    modes = {
      ---@diagnostic disable-next-line
      diagnostic_preview_float = {
        mode = "diagnostics",
        preview = {
          type = "float",
          relative = "editor",
          border = borders.default,
          title = " Preview ",
          title_pos = "center",
          position = { 0, -2 },
          size = { width = 0.3, height = 0.3 },
          zindex = 200,
        },
      },
    },
  },
  todo = {
    keywords = {
      WORKAROUND = {
        icon = " ",
        color = "warning",
      },
    },
  },
}
