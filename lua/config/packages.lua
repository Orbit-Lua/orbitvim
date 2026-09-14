local tools = require("config.tools")

local M = {
  lsp_servers = {},
  mason_ensure_installed = {},
  treesitter_ensure_installed = {},
  formatters_by_ft = {},
  linters_by_ft = {},
}

local function sorted_keys(tbl)
  local keys = vim.tbl_keys(tbl or {})
  table.sort(keys)
  return keys
end

local function derive_by_ft(category)
  local routed = {}

  for _, name in ipairs(sorted_keys(tools[category])) do
    local definition = tools[category][name]
    for _, filetype in ipairs(definition.ft) do
      routed[filetype] = routed[filetype] or {}
      table.insert(routed[filetype], {
        name = name,
        order = definition.order or 100,
      })
    end
  end

  local result = {}
  for filetype, entries in pairs(routed) do
    table.sort(entries, function(a, b)
      if a.order == b.order then
        return a.name < b.name
      end
      return a.order < b.order
    end)

    result[filetype] = {}
    for _, entry in ipairs(entries) do
      table.insert(result[filetype], entry.name)
    end
  end

  return result
end

for _, name in ipairs(sorted_keys(tools.parser)) do
  table.insert(M.treesitter_ensure_installed, name)
end

local mason = {}
local function collect_mason(pkg)
  if pkg then
    mason[pkg] = true
  end
end

for _, name in ipairs(sorted_keys(tools.lsp)) do
  local definition = tools.lsp[name]
  table.insert(M.lsp_servers, name)
  collect_mason(definition.mason)
end

for _, category in ipairs({ "dap", "linter", "formatter" }) do
  for _, name in ipairs(sorted_keys(tools[category])) do
    collect_mason(tools[category][name].mason)
  end
end

for _, name in ipairs(sorted_keys(tools.package)) do
  if tools.package[name].source == "mason" then
    collect_mason(name)
  end
end

M.mason_ensure_installed = sorted_keys(mason)
M.formatters_by_ft = derive_by_ft("formatter")
M.linters_by_ft = derive_by_ft("linter")

return M
