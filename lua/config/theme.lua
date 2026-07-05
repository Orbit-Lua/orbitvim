local M = {}

local nvui_path = vim.fn.stdpath("config") .. "/lua/config/nvui.lua"

local function base46_theme_path()
  local base46 = require("base46")
  return vim.fn.fnamemodify(
    debug.getinfo(base46.merge_tb, "S").source:sub(2),
    ":p:h"
  ) .. "/themes"
end

function M.list()
  local themes = vim.fn.readdir(base46_theme_path())
  local custom_path = vim.fn.stdpath("config") .. "/lua/themes"

  if vim.uv.fs_stat(custom_path) then
    vim.list_extend(themes, vim.fn.readdir(custom_path))
  end

  for index, theme in ipairs(themes) do
    themes[index] = theme:match("(.+)%..+") or theme
  end

  table.sort(themes)
  return themes
end

local function persist_theme(name)
  local file = io.open(nvui_path, "rb")
  if not file then
    return false
  end

  local content = file:read("*a")
  file:close()
  content = content:gsub("\r\n", "\n")

  local updated, count = content:gsub('theme = "[^"]+"', function()
    return 'theme = "' .. name .. '"'
  end, 1)

  if count == 0 then
    return false
  end

  file = io.open(nvui_path, "wb")
  if not file then
    return false
  end

  file:write(updated)
  file:close()
  return true
end

function M.reload(name)
  require("nvconfig").base46.theme = name
  require("base46").load_all_highlights()
  pcall(require("plenary.reload").reload_module, "volt.highlights")
  pcall(require, "volt.highlights")
end

function M.load_cache(name)
  local ok, err = pcall(function()
    dofile(vim.g.base46_cache .. name)
  end)
  if not ok then
    vim.notify("[theme] " .. tostring(err), vim.log.levels.WARN)
  end
end

function M.set(name, opts)
  opts = opts or {}

  package.loaded["config.nvui"] = nil
  package.loaded.nvconfig = nil
  package.loaded.base46 = nil

  if opts.persist and not persist_theme(name) then
    vim.notify("[theme] failed to persist theme", vim.log.levels.WARN)
  end

  local ok, err = pcall(M.reload, name)
  if not ok then
    vim.notify("[theme] " .. tostring(err), vim.log.levels.WARN)
  end
end

function M.open()
  vim.ui.select(M.list(), { prompt = "Set theme" }, function(choice)
    if choice then
      M.set(choice, { persist = true })
    end
  end)
end

return M
