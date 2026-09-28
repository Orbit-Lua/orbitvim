local ignored = {
  lsp = {
    -- "is not accessed",
    -- "Unused local",
  },

  notify = {
    "man.lua",
    "roslyn: %-32000",
    "roslyn: %-30099",
    "lua_ls: %-32603",
  },

  msg_show = {
    "; after #%d+",
    "; before #%d+",

    "%d+L, %d+B",
    "%d+ fewer lines",
    "%d+ more lines",
    "%d+ lines yanked",
    "%d+ lines moved",
    "%d+ lines [><]ed%s+%d+ time",

    "Error INVALID_SERVER_MESSAGE: nil",
    "snacks/util/init.lua:207: Invalid window id",
  },

  progress = {
    "Searching in files",
    "pyright",
  },
}

return ignored
