local LazyUtil = require("lazy.core.util")
local M = {}

setmetatable(M, {
  __index = function(_, k)
    if LazyUtil[k] then
      return LazyUtil[k]
    end

    return nil
  end,
})

M.lsp = require("utils.lsp")
M.ft = require("utils.ft")
M.shell = require("utils.shell")
M.os = require("utils.os")
M.config = require("config")
M.fs = require("utils.fs")
M.cmp = require("utils.cmp")
M.buffer = require("utils.buffer")
M.hl = require("utils.hl")
M.term = require("utils.term")
M.ui = require("utils.ui")
M.str = require("utils.str")
M.table = require("utils.table")
M.logger = require("utils.logger")

M.CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
function M.create_undo()
  if vim.api.nvim_get_mode().mode == "i" then
    vim.api.nvim_feedkeys(M.CREATE_UNDO, "n", false)
  end
end

---@diagnostic disable: deprecated
M.unpack = table.unpack or unpack

for _, level in ipairs({ "info", "warn", "error" }) do
  M[level] = function(msg, opts)
    opts = opts or {}
    opts.title = opts.title or "Neovim"
    return LazyUtil[level](msg, opts)
  end
end

return M
