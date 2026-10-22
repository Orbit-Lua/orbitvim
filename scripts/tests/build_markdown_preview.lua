vim.opt.runtimepath:prepend(vim.fn.getcwd())
local directory = vim.fn.stdpath("data") .. "/lazy/markdown-preview.nvim"
for _, plugin in ipairs(require("plugins.editor")) do
  if plugin[1] == "iamcco/markdown-preview.nvim" then
    plugin.build({ dir = directory })
  end
end
local result = vim
  .system(
    { directory .. "/app/bin/markdown-preview-win.exe", "--version" },
    { text = true }
  )
  :wait(10000)
local info = vim.json.decode(
  table.concat(vim.fn.readfile(directory .. "/package.json"), "\n")
)
assert(result.code == 0, result.stderr)
assert(
  vim.trim(result.stdout) == info.version,
  "Markdown preview executable has the wrong version"
)
print("Markdown preview installation and executable version passed")
