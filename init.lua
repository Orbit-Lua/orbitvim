--------------------------------------------------------------------------------
-- 1. Pre-Lazy: environment, options, autocmds, and filetypes
--------------------------------------------------------------------------------
vim.g.base46_cache = vim.fn.stdpath("data") .. "/nvchad/base46/"
vim.g.mapleader = " "

require("core.options")
require("features.settings.runtime").setup()
require("core.autocmds")
require("core.filetypes")

--------------------------------------------------------------------------------
-- 2. Bootstrap & Setup lazy.nvim
--------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if vim.v.shell_error ~= 0 or not vim.uv.fs_stat(lazypath) then
    error(
      "Failed to bootstrap lazy.nvim (git clone exited "
        .. vim.v.shell_error
        .. "): "
        .. vim.trim(output)
    )
  end
  local lock_path = vim.fn.stdpath("config") .. "/lazy-lock.json"
  if vim.fn.filereadable(lock_path) == 1 then
    local lock = vim.json.decode(table.concat(vim.fn.readfile(lock_path), "\n"))
    local revision = lock["lazy.nvim"] and lock["lazy.nvim"].commit
    if revision then
      local checkout = vim.fn.system({
        "git",
        "-C",
        lazypath,
        "checkout",
        "--detach",
        revision,
      })
      if vim.v.shell_error ~= 0 then
        error(
          "Failed to check out locked lazy.nvim revision: "
            .. vim.trim(checkout)
        )
      end
    end
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { import = "plugins" },
}, require("core.lazy"))

--------------------------------------------------------------------------------
-- 3. Post-Lazy: user commands, theme caches, shell, and keymaps
--------------------------------------------------------------------------------
require("core.commands").setup()

local theme = require("features.theme.runtime")
theme.load_cache("defaults")
theme.load_cache("statusline")

require("core.shell").setup()
require("utils.hl").setup()

require("core.keymaps")
