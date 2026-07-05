local M = {}

local fs = require("utils.fs")
local highlights = require("utils.hl")
local shell = require("utils.shell")
local startup = require("config.startup")
local theme = require("config.theme")

function M.setup()
  startup.close_lazy_view()
  startup.load_options()

  require("config.events")
  require("config.autocmds")
  require("config.filetypes")

  for _, cmd_file in ipairs(fs.scandir(fs.config_path .. "/lua/cmds", "file")) do
    require("cmds." .. vim.fn.fnamemodify(cmd_file, ":r"))
  end

  theme.load_cache("defaults")
  theme.load_cache("statusline")
  shell.setup()
  highlights.setup()

  vim.schedule(function()
    require("config.keymaps")
  end)
end

return M
