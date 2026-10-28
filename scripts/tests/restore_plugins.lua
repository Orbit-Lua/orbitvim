local repository = vim.fn.getcwd()
package.path = repository .. "/?.lua;" .. package.path
vim.opt.runtimepath:prepend(repository)
local fixture = vim.fn.tempname()
local previous_path = vim.env.PATH
vim.env.PATH =
  require("scripts.tests.roslyn_fixture").path(fixture .. "/bin", previous_path)
vim.fn.mkdir(fixture .. "/vault", "p")
vim.g.orbitvim_settings_path = fixture .. "/settings.json"
vim.g.hangar_state_path = fixture .. "/hangar.json"
assert(
  vim.fn.writefile(
    { vim.json.encode({ notes = { vault = fixture .. "/vault" } }) },
    vim.g.orbitvim_settings_path
  ) == 0
)
local state = {}
for _, category in ipairs({ "lsp", "dap", "formatter", "linter" }) do
  state[category] = {}
  for name in pairs(require("features.hangar.config")[category]) do
    state[category][name] = false
  end
end
assert(
  vim.fn.writefile({ vim.json.encode(state) }, vim.g.hangar_state_path) == 0
)
local ok, err = xpcall(function()
  dofile("init.lua")
  require("lazy").restore({ wait = true, show = false })

  local active = {}
  for _, plugin in ipairs(require("lazy").plugins()) do
    active[plugin.name] = true
  end

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
  for name in pairs(active) do
    assert(lock[name], name .. " is missing from the lockfile")
  end
  io.stdout:write("All locked plugin revisions match the lockfile\n")
end, debug.traceback)
vim.env.PATH = previous_path
vim.fn.delete(fixture, "rf")
assert(ok, err)
vim.cmd.qall()
