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

  local ok, err = pcall(function()
    dofile(vim.g.base46_cache .. "defaults")
    dofile(vim.g.base46_cache .. "statusline")
  end)
  if not ok then
    vim.notify("[theme] " .. tostring(err), vim.log.levels.WARN)
  end

  utils.shell.setup()
  utils.hl.setup()

  vim.schedule(function()
    require("config.keymaps")
  end)
end

return M
