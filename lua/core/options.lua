local opt = vim.opt
local o = vim.o
local g = vim.g

-- Prepend Mason bin directory to PATH
local is_windows = vim.fn.has("win32") ~= 0
local sep = is_windows and "\\" or "/"
local delim = is_windows and ";" or ":"
vim.env.PATH = table.concat({ vim.fn.stdpath("data"), "mason", "bin" }, sep)
  .. delim
  .. vim.env.PATH

-- General editor options
o.laststatus = 3
o.showmode = false
o.splitkeep = "screen"

o.clipboard = "unnamedplus"
o.cursorlineopt = "number"

o.smartindent = true

opt.fillchars = { eob = " " }
o.mouse = "a"

o.numberwidth = 2
o.ruler = false

opt.shortmess:append("sI")
o.shm = vim.o.shm .. "I"

o.signcolumn = "yes"
o.undofile = true

o.fileformats = "unix,dos"
o.autoread = true

opt.whichwrap:append("<>[]hl")

-- Disable unused providers
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

-- Feature globals
g.snacks_animate = false
