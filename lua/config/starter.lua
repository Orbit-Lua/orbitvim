local M = {}

function M.setup()
  local utils = require("utils")

  utils.ui.close_lazy_view()
  utils.ui.load_options()

  require("config.events")
  require("config.autocmds")
  require("config.filetypes")

  for _, cmd_file in
    ipairs(utils.fs.scandir(utils.fs.config_path .. "/lua/cmds", "file"))
  do
    require("cmds." .. vim.fn.fnamemodify(cmd_file, ":r"))
  end

  utils.ui.load_base46_cache("defaults")
  utils.ui.load_base46_cache("statusline")
  utils.shell.setup()
  utils.hl.setup()

  vim.schedule(function()
    require("config.keymaps")
  end)
end

return M
