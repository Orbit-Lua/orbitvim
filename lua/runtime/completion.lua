local M = {}

function M.build_luasnip(plugin)
  local command = { "make", "install_jsregexp" }
  if vim.fn.has("win32") == 1 then
    local executable = vim.uv.fs_realpath(vim.v.progpath) or vim.v.progpath
    table.insert(
      command,
      2,
      "NEOVIM_BIN_PATH=" .. vim.fs.dirname(vim.fs.normalize(executable))
    )
  end
  local result =
    vim.system(command, { cwd = plugin.dir, text = true }):wait(120000)
  if result.code ~= 0 then
    error(
      "LuaSnip native build failed:\n"
        .. (result.stderr or "")
        .. (result.stdout or ""),
      0
    )
  end
end

function M.setup_luasnip(opts)
  local luasnip = require("luasnip")
  luasnip.config.set_config(opts)
  luasnip.filetype_extend("jsx", { "javascript", "javascriptreact" })
  luasnip.filetype_extend("sql", { "tsql" })
  require("runtime.snippets").setup()
end

return M
