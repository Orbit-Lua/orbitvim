---@meta _

stds = { "luajit" }
cache = true
codes = true
read_globals = { "vim" }
files["tests/**"] = {
  read_globals = { "assert", "describe", "it", "before_each", "after_each" },
}
