--------------------------------------------------------------------------------
-- 1. Pre-Lazy: environment, options, autocmds, and filetypes
--------------------------------------------------------------------------------
vim.g.base46_cache = vim.fn.stdpath("data") .. "/nvchad/base46/"
vim.g.mapleader = " "

require("config.options")
require("config.autocmds")
require("config.filetypes")

--------------------------------------------------------------------------------
-- 2. Bootstrap & Setup lazy.nvim
--------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { import = "plugins" },
}, require("config.lazy"))

--------------------------------------------------------------------------------
-- 3. Post-Lazy: user commands, theme caches, shell, and keymaps
--------------------------------------------------------------------------------
require("cmds").setup()

local theme = require("config.theme")
theme.load_cache("defaults")
theme.load_cache("statusline")

require("utils.shell").setup()
require("utils.hl").setup()

require("config.keymaps")
