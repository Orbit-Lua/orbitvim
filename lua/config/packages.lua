local tools = require("config.tools")

local M = {}

-- Derive consumer-specific lists from the tool registry so config/tools.lua
-- remains the single source of truth.
M.lsp_servers = {}
M.mason_ensure_installed = {}
M.treesitter_ensure_installed = {}

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

for _, name in ipairs(sorted_keys(tools.parser)) do
  table.insert(M.treesitter_ensure_installed, name)
end

local derived_mason_packages = {}
local function collect_mason(pkg)
  if pkg then
    derived_mason_packages[pkg] = true
  end
end

for _, name in ipairs(sorted_keys(tools.lsp)) do
  local meta = tools.lsp[name]
  table.insert(M.lsp_servers, name)
  collect_mason(meta.mason)
end

for _, cat in ipairs({ "dap", "linter", "formatter" }) do
  for _, name in ipairs(sorted_keys(tools[cat])) do
    local meta = tools[cat][name]
    collect_mason(meta.mason)
  end
end

for _, name in ipairs(sorted_keys(tools.package)) do
  local meta = tools.package[name]
  if meta.source == "mason" then
    collect_mason(name)
  end
end

for _, pkg in ipairs(sorted_keys(derived_mason_packages)) do
  add_mason(pkg)
end

return M
