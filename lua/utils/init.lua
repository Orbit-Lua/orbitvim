local LazyUtil = require("lazy.core.util")
local M = {}

local modules = {
  lsp = "utils.lsp",
  ft = "utils.ft",
  shell = "utils.shell",
  os = "utils.os",
  config = "config",
  fs = "utils.fs",
  cmp = "utils.cmp",
  buffer = "utils.buffer",
  hl = "utils.hl",
  term = "utils.term",
  ui = "utils.ui",
  str = "utils.str",
  table = "utils.table",
  logger = "utils.logger",
  window = "utils.window",
  icons = "utils.icons",
  tree = "utils.tree",
  harpoon = "utils.harpoon",
}

setmetatable(M, {
  __index = function(_, k)
    local module = modules[k]
    if module then
      local value = require(module)
      rawset(M, k, value)
      return value
    end

    if LazyUtil[k] then
      return LazyUtil[k]
    end

    return nil
  end,
})

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
