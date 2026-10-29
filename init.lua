--------------------------------------------------------------------------------
-- Core editor state remains available in empty headless sessions.
--------------------------------------------------------------------------------
vim.g.base46_cache = vim.fn.stdpath("data") .. "/nvchad/base46/"
vim.g.mapleader = " "

require("core.options")
require("features.settings.runtime").setup()
require("core.autocmds")
require("core.filetypes")

-- Initialize plugins before their first UI, file, command, or module use.
require("core.startup").setup()
require("core.commands").setup()
require("core.shell").setup()
require("core.keymaps")
