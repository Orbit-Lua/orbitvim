local borders = require("config.borders")

return {
  short_path_length = 8,
  oil = {
    default_file_explorer = false,
    delete_to_trash = true,
    keymaps = {
      -- ["g."] = false,
      ["<C-h>"] = false,
      ["<C-l>"] = false,
      ["<C-p>"] = false,
      ["-"] = false,
      ["`"] = false,
      ["s"] = { "<cmd>write<CR>", mode = "n", desc = "sync/apply changes" },
      ["R"] = "actions.refresh",
      ["H"] = "actions.toggle_hidden",
      ["."] = "actions.cd",
      ["<BS>"] = "actions.parent",
      [";"] = { ":", mode = "n", desc = "command mode" },
    },
    float = {
      max_width = 0.9,
      max_height = 0.9,
      border = borders.default,
      preview_split = "right",
    },
  },
  harpoon = {},
}
