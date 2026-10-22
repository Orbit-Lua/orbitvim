vim.opt.runtimepath:prepend(vim.fn.getcwd())
dofile("init.lua")
require("lazy").restore({ wait = true, show = false })

local lock =
  vim.json.decode(table.concat(vim.fn.readfile("lazy-lock.json"), "\n"))
for name, entry in pairs(lock) do
  local result = vim
    .system({
      "git",
      "-C",
      vim.fn.stdpath("data") .. "/lazy/" .. name,
      "rev-parse",
      "HEAD",
    }, { text = true })
    :wait(10000)
  assert(result.code == 0, name .. ": " .. (result.stderr or ""))
  assert(
    vim.trim(result.stdout) == entry.commit,
    name .. " differs from the lockfile"
  )
end
io.stdout:write("All plugin revisions match the lockfile\n")
vim.cmd.qall()
