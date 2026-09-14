vim.g.base46_cache = vim.fn.stdpath("data") .. "/nvchad/base46/"
vim.g.mapleader = " "

local function lazy_lock_commit()
  local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
  local ok, lines = pcall(vim.fn.readfile, lockfile)
  if not ok then
    error("Failed to read lazy-lock.json")
  end

  local decoded_ok, lock = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded_ok or type(lock) ~= "table" then
    error("Failed to parse lazy-lock.json")
  end

  local entry = lock["lazy.nvim"]
  if type(entry) ~= "table" or type(entry.commit) ~= "string" then
    error("lazy-lock.json does not pin lazy.nvim")
  end

  return entry.commit
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local result = vim.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--no-checkout",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  }, { text = true }):wait()

  if result.code ~= 0 then
    error(
      "Failed to bootstrap lazy.nvim:\n"
        .. (result.stderr or result.stdout or "unknown error")
    )
  end

  local checkout = vim.system({
    "git",
    "-C",
    lazypath,
    "checkout",
    "--detach",
    lazy_lock_commit(),
  }, { text = true }):wait()

  if checkout.code ~= 0 then
    error(
      "Failed to checkout pinned lazy.nvim:\n"
        .. (checkout.stderr or checkout.stdout or "unknown error")
    )
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { import = "plugins" },
}, require("config.lazy"))

require("config.starter").setup()
