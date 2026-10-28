local M = {}

function M.setup()
  require("features.settings.commands").setup()
  require("features.python.commands").setup()
  require("core.system").setup()
  require("features.treesitter.commands").setup()
  require("features.hangar.commands").setup()
end

return M
