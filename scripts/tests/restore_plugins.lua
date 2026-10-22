vim.opt.runtimepath:prepend(vim.fn.getcwd())
dofile("init.lua")
require("lazy").restore({ wait = true, show = false })

-- Lazy installs only plugins whose cond holds here; roslyn.nvim, for one,
-- needs dotnet and its server on PATH. Their lock entries stay as they are.
local active = {}
for _, plugin in ipairs(require("lazy").plugins()) do
  active[plugin.name] = true
end

local lock =
  vim.json.decode(table.concat(vim.fn.readfile("lazy-lock.json"), "\n"))
local skipped = {}
for name, entry in pairs(lock) do
  if active[name] then
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
  else
    table.insert(skipped, name)
  end
end
for name in pairs(active) do
  assert(lock[name], name .. " is missing from the lockfile")
end
table.sort(skipped)
io.stdout:write("All active plugin revisions match the lockfile\n")
if #skipped > 0 then
  io.stdout:write("Inactive here: " .. table.concat(skipped, ", ") .. "\n")
end
vim.cmd.qall()
