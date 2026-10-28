local controller = vim.fn.getcwd()
local repository = arg[2] or controller
package.path = controller .. "/?.lua;" .. package.path
local session =
  require("scripts.tests.session").open(repository, { file = "fixture.lua" })
-- Script numbers vary with source order. Compare the same script identity.
local normalize = [[
local scripts = {}
for _, script in ipairs(vim.fn.getscriptinfo()) do
  local path = vim.fs.normalize(vim.fn.resolve(script.name))
  local identity = path:match('/lazy/(.+)')
    or path:match('/nvim/runtime/(.+)')
    or path:sub(#(...) + 2)
  scripts[script.sid] = identity
end
local function stable(value)
  if type(value) ~= 'string' then return value end
  return (value:gsub('<SNR>(%d+)_', function(sid)
    return '<SNR:' .. assert(scripts[tonumber(sid)], 'unknown script mapping') .. '>_'
  end))
end
]]
local function capture()
  return session.exec(normalize .. [[
local result = {}
for _, mode in ipairs({'n','v','x','s','o','i','l','c','t'}) do
  for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
    if mapping.desc or mapping.callback or mapping.rhs ~= '' then
      result[#result+1] = {
        mode = mode, lhs = stable(mapping.lhs), rhs = stable(mapping.rhs),
        callback = mapping.callback ~= nil, expr = mapping.expr,
        noremap = mapping.noremap, nowait = mapping.nowait,
        silent = mapping.silent,
      }
    end
  end
end
table.sort(result, function(a,b) return a.mode..a.lhs < b.mode..b.lhs end)
return result
]], { repository })
end
local ok, result = pcall(function()
  local snapshots = { startup = capture() }
  session.exec([[
local names = {}
for _, plugin in ipairs(require('lazy').plugins()) do
  names[#names+1] = plugin.name
end
require('lazy').load({plugins=names})
]])
  snapshots.loaded = capture()
  snapshots.lsp = session.exec(normalize .. [[
local result = {}
local original = vim.lsp.get_clients
for _, name in ipairs({'lua_ls','pyright','ruff','roslyn','typescript-tools','prismals'}) do
  local buffer = vim.api.nvim_create_buf(true, false)
  vim.lsp.get_clients = function()
    return {{name=name, supports_method=function() return true end}}
  end
  require('features.lsp.runtime.keymaps').on_attach(nil, buffer)
  result[name] = {}
  for _, mode in ipairs({'n','v','i'}) do
    for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buffer, mode)) do
      result[name][#result[name]+1] = {
        mode=mode, lhs=stable(mapping.lhs), rhs=stable(mapping.rhs),
        callback=mapping.callback ~= nil, expr=mapping.expr,
        noremap=mapping.noremap, nowait=mapping.nowait, silent=mapping.silent,
      }
    end
  end
  table.sort(result[name], function(a,b) return a.mode..a.lhs < b.mode..b.lhs end)
end
vim.lsp.get_clients = original
return result
]], { repository })
  return snapshots
end)
session.close()
assert(ok, result)
assert(arg[1], "provide an output path outside the repository")
assert(vim.fn.writefile({ vim.json.encode(result) }, arg[1]) == 0)
