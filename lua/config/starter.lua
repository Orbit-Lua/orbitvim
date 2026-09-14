local M = {}

local fs = require("utils.fs")
local highlights = require("utils.hl")
local shell = require("utils.shell")
local theme = require("config.theme")

local function load_options()
  local defaults_ok = pcall(require, "config.defaults")
  local options_ok = pcall(require, "config.options")
  if not defaults_ok or not options_ok then
    vim.notify(
      "Failed to load options. Please check your configuration.",
      vim.log.levels.ERROR
    )
  end
end

function M.setup()
  load_options()

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
