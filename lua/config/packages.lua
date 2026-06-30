local services = require("config.services")

local M = {}

M.treesitter_ensure_installed = {
  "lua",
  "luadoc",
  "printf",
  "vim",
  "vimdoc",
  "html",
  "css",
  "javascript",
  "typescript",
  "tsx",
  "c",
  "cpp",
  "python",
  "bash",
  "markdown",
  "sql",
  "prisma",
  "comment",
  "c_sharp",
  "xml",
  "go",
  "regex",
}

-- Mason packages that are installed but not tracked as managed services.
local mason_extras = {
  "markdownlint", -- standalone markdown linter (separate from markdownlint-cli2)
}

-- Derive lsp_servers and mason_ensure_installed from the services registry so that
-- config/services.lua is the single source of truth for all managed services.
M.lsp_servers = {}
M.mason_ensure_installed = {
  "typescript-language-server", -- for tsserver executable
}

local function sorted_keys(tbl)
  local keys = vim.tbl_keys(tbl or {})
  table.sort(keys)
  return keys
end

local seen = {}
local function add_mason(pkg)
  if pkg and not seen[pkg] then
    seen[pkg] = true
    table.insert(M.mason_ensure_installed, pkg)
  end
end

local derived_mason_packages = {}
local function collect_mason(pkg)
  if pkg then
    derived_mason_packages[pkg] = true
  end
end

for _, name in ipairs(sorted_keys(services.lsp)) do
  local meta = services.lsp[name]
  table.insert(M.lsp_servers, name)
  collect_mason(meta.mason)
end

for _, cat in ipairs({ "dap", "linter", "formatter" }) do
  for _, name in ipairs(sorted_keys(services[cat])) do
    local meta = services[cat][name]
    collect_mason(meta.mason)
  end
end

for _, pkg in ipairs(mason_extras) do
  collect_mason(pkg)
end

for _, pkg in ipairs(sorted_keys(derived_mason_packages)) do
  add_mason(pkg)
end

return M
