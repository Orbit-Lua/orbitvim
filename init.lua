vim.g.base46_cache = vim.fn.stdpath("data") .. "/nvchad/base46/"
vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local result = vim.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }, { text = true }):wait()

  if result.code ~= 0 then
    error("Failed to bootstrap lazy.nvim:\n" .. (result.stderr or result.stdout or "unknown error"))
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { import = "plugins" },
}, require("config.lazy"))

require("config.starter").setup()
