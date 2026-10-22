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
  harpoon = {
    -- https://github.com/ThePrimeagen/harpoon/blob/harpoon2/lua/harpoon/config.lua
    default = {
      -- refer to: https://github.com/ThePrimeagen/harpoon/issues/523#issuecomment-1984926994
      --
      create_list_item = function(config, value)
        return require("runtime.harpoon").create_list_item(config, value)
      end,

      display = function(list_item)
        local path = list_item.context.short_path or ""
        return require("runtime.harpoon").format_display(path)
      end,
    },
  },
}
