local map = vim.keymap.set
local fs = require("utils.fs")
local ui = require("utils.ui")
local utils_cmp = require("utils.cmp")

map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  utils_cmp.actions.snippet_stop()
  return "<esc>"
end, { expr = true, desc = "escape and clear hlsearch" })

-------------------- file, buffer, tab --------------------
map("n", "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })
map("n", "<leader>fu", function()
  vim.cmd("e ++ff=dos")
  vim.cmd("set ff=unix")
  vim.cmd("w")
end, { desc = "reload file as unix format (from dos)" })
map("n", "<leader>bn", "<cmd>enew<CR>", { desc = "buffer new" })
map("n", "<leader>bD", "<cmd>%bd|e#<cr>", { desc = "buffer close others" })
map("n", "<tab>", function()
  require("utils.buffer").next()
end, { desc = "buffer goto next" })
map("n", "<S-tab>", function()
  require("utils.buffer").prev()
end, { desc = "buffer goto prev" })
map("n", "<leader>fi", function()
  vim.cmd("e ++enc=big5")
  vim.cmd("set fileencoding=utf-8")
  vim.cmd("w")
end, { desc = "reload file as utf-8 format (from big5)" })
map("n", "<leader>x", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "close current file" })

-------------------- navigation  --------------------
map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })
map("n", "<leader>fd", function()
  vim.cmd("cd " .. fs.get_root())
end, { desc = "set cwd to file root" })

-------------------- terminal --------------------
map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })
map("n", "<leader>h", function()
  require("utils.term").new({ pos = "sp" })
end, { desc = "terminal new horizontal term" })
map("n", "<leader>v", function()
  require("utils.term").new({ pos = "vsp" })
end, { desc = "terminal new vertical term" })
map({ "n", "t" }, "<M-v>", function()
  if ui.check_toggle_term() then
    require("utils.term").toggle({ pos = "vsp", id = "vtoggleTerm" })
  end
end, { desc = "terminal toggleable vertical term" })
map({ "n", "t" }, "<M-h>", function()
  if ui.check_toggle_term() then
    require("utils.term").toggle({ pos = "sp", id = "htoggleTerm" })
  end
end, { desc = "terminal toggleable horizontal term" })
map({ "n", "t" }, "<M-i>", function()
  if ui.check_toggle_term() then
    require("utils.term").toggle({ pos = "float", id = "floatTerm" })
  end
end, { desc = "terminal toggle floating term" })

-------------------- common --------------------
map("n", ";", ":", { desc = "cmd enter command mode" })
map("n", "<", "<<", { desc = "indent backward easily" })
map("n", ">", ">>", { desc = "indent forward easily" })
map("x", "<", "<gv", { desc = "indent backward and stay in visual mode" })
map("x", ">", ">gv", { desc = "indent forward and stay in visual mode" })
map(
  "x",
  "J",
  ":move '>+1<CR>gv-gv",
  { desc = "move selected block up and stay in visual mode" }
)
map(
  "x",
  "K",
  ":move '<-2<CR>gv-gv",
  { desc = "move selected block down and stay in visual mode" }
)
map("x", "p", "P", { desc = "paste without yanking replaced text" })
map("i", "jk", "<ESC>")
map("n", "<leader>q", "q", { desc = "record macro" })
map("n", "q", "<Nop>", { silent = true })
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-------------------- notification --------------------
map("n", "<leader>tf", function()
  vim.diagnostic.open_float()
end, { desc = "floating diagnostic" })

-------------------- theme --------------------
map("n", "<leader>ut", function()
  require("config.theme").open()
end, { desc = "theme picker" })
