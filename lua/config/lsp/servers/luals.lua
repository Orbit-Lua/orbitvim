local data_path = vim.fs.normalize(vim.fn.stdpath("data"))

---@type Lsp.Server.Module
return {
  servers = {
    lua_ls = {
      settings = {
        Lua = {
          codeLens = { enable = true },
          hint = {
            enable = true,
            paramName = "Literal",
            paramType = true,
            setType = true,
            arrayIndex = "Auto",
            await = true,
            semicolon = "Disable",
          },
          runtime = { version = "LuaJIT" },
          workspace = {
            library = {
              vim.fn.expand("$VIMRUNTIME/lua"),
              "${3rd}/luv/library",
              data_path .. "/lazy/lazy.nvim/lua/lazy",
            },
          },
        },
      },
    },
  },
}
