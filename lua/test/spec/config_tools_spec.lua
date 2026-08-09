describe("config.tools", function()
  local tools = require("config.tools")

  describe("top-level tables", function()
    it("exposes lsp", function()
      assert.is_true(type(tools.lsp) == "table")
    end)

    it("exposes dap", function()
      assert.is_true(type(tools.dap) == "table")
    end)

    it("exposes linter", function()
      assert.is_true(type(tools.linter) == "table")
    end)

    it("exposes formatter", function()
      assert.is_true(type(tools.formatter) == "table")
    end)

    it("exposes parser and package definitions", function()
      assert.is_true(type(tools.parser) == "table")
      assert.is_true(type(tools.package) == "table")
    end)

    it("exposes formatter_defaults", function()
      assert.is_true(type(tools.formatter_defaults) == "table")
    end)

    it("exposes linter_defaults", function()
      assert.is_true(type(tools.linter_defaults) == "table")
    end)
  end)

  describe("parser entries", function()
    it("maps parser names to filetypes and Treesitter", function()
      assert.same({ "lua" }, tools.parser.lua.ft)
      assert.is_true(vim.tbl_contains(tools.parser.tsx.ft, "typescriptreact"))
      assert.equals("treesitter", tools.parser.tsx.source)
    end)
  end)

  describe("package entries", function()
    it("tracks TypeScript's Mason dependency", function()
      local dependency = tools.package["typescript-language-server"]
      assert.equals("mason", dependency.source)
      assert.equals("dependency", dependency.role)
    end)
  end)

  describe("lsp entries", function()
    it("each entry has a mason field (string or nil)", function()
      for name, meta in pairs(tools.lsp) do
        assert.is_true(
          meta.mason == nil or type(meta.mason) == "string",
          name .. ".mason must be string or nil"
        )
      end
    end)

    it("each entry has a non-empty ft array", function()
      for name, meta in pairs(tools.lsp) do
        assert.is_not_nil(meta.ft, name .. ".ft must exist")
        assert.is_true(type(meta.ft) == "table", name .. ".ft must be a table")
        assert.is_true(#meta.ft > 0, name .. ".ft must be non-empty")
      end
    end)

    it("each ft value is a string", function()
      for name, meta in pairs(tools.lsp) do
        for _, ft in ipairs(meta.ft) do
          assert.is_true(
            type(ft) == "string",
            name .. " ft entry must be a string"
          )
        end
      end
    end)

    it("contains lua_ls pointing at lua", function()
      assert.is_not_nil(tools.lsp.lua_ls)
      assert.is_true(vim.tbl_contains(tools.lsp.lua_ls.ft, "lua"))
    end)

    it("contains pyright pointing at python", function()
      assert.is_not_nil(tools.lsp.pyright)
      assert.is_true(vim.tbl_contains(tools.lsp.pyright.ft, "python"))
    end)

    it("contains jsonls pointing at json", function()
      assert.is_not_nil(tools.lsp.jsonls)
      assert.is_true(vim.tbl_contains(tools.lsp.jsonls.ft, "json"))
    end)
  end)

  describe("dap entries", function()
    it("each entry has a non-empty ft array", function()
      for name, meta in pairs(tools.dap) do
        assert.is_not_nil(meta.ft, name .. ".ft must exist")
        assert.is_true(#meta.ft > 0, name .. ".ft must be non-empty")
      end
    end)

    it("contains coreclr for C#", function()
      assert.is_not_nil(tools.dap.coreclr)
      assert.is_true(vim.tbl_contains(tools.dap.coreclr.ft, "cs"))
    end)

    it("contains python adapter", function()
      assert.is_not_nil(tools.dap.python)
    end)
  end)

  describe("linter entries", function()
    it("each entry has a mason field (string)", function()
      for name, meta in pairs(tools.linter) do
        assert.is_true(
          type(meta.mason) == "string",
          name .. ".mason must be a string"
        )
      end
    end)

    it("each entry has a non-empty ft array", function()
      for name, meta in pairs(tools.linter) do
        assert.is_true(#meta.ft > 0, name .. ".ft must be non-empty")
      end
    end)

    it("contains luacheck for lua", function()
      assert.is_not_nil(tools.linter.luacheck)
      assert.is_true(vim.tbl_contains(tools.linter.luacheck.ft, "lua"))
    end)

    it("contains sqlfluff for sql filetypes", function()
      assert.is_not_nil(tools.linter.sqlfluff)
      assert.is_true(vim.tbl_contains(tools.linter.sqlfluff.ft, "sql"))
    end)
  end)

  describe("formatter entries", function()
    it("each entry has a non-empty ft array", function()
      for name, meta in pairs(tools.formatter) do
        assert.is_true(#meta.ft > 0, name .. ".ft must be non-empty")
      end
    end)

    it("contains stylua for lua", function()
      assert.is_not_nil(tools.formatter.stylua)
      assert.equals("lua", tools.formatter.stylua.ft[1])
      assert.equals("stylua", tools.formatter.stylua.mason)
    end)

    it(
      "ruff_fix / ruff_format / ruff_organize_imports all map to ruff mason pkg",
      function()
        assert.equals("ruff", tools.formatter.ruff_fix.mason)
        assert.equals("ruff", tools.formatter.ruff_format.mason)
        assert.equals("ruff", tools.formatter.ruff_organize_imports.mason)
      end
    )

    it("prisma_fmt has no mason package (uses node_modules)", function()
      assert.is_not_nil(tools.formatter.prisma_fmt)
      assert.is_nil(tools.formatter.prisma_fmt.mason)
    end)
  end)

  describe("formatter_defaults", function()
    it("python order starts with ruff_fix", function()
      assert.is_not_nil(tools.formatter_defaults.python)
      assert.equals("ruff_fix", tools.formatter_defaults.python[1])
    end)

    it("python order contains ruff_organize_imports", function()
      assert.is_true(
        vim.tbl_contains(
          tools.formatter_defaults.python,
          "ruff_organize_imports"
        )
      )
    end)

    it("python order contains ruff_format", function()
      assert.is_true(
        vim.tbl_contains(tools.formatter_defaults.python, "ruff_format")
      )
    end)

    it(
      "every formatter referenced in defaults exists in the formatter table",
      function()
        for ft, order in pairs(tools.formatter_defaults) do
          for _, name in ipairs(order) do
            assert.is_not_nil(
              tools.formatter[name],
              name
                .. " in formatter_defaults["
                .. ft
                .. "] is missing from tools.formatter"
            )
          end
        end
      end
    )

    it("markdown order contains deno_fmt", function()
      if tools.formatter_defaults.markdown then
        assert.is_true(
          vim.tbl_contains(tools.formatter_defaults.markdown, "deno_fmt")
        )
      end
    end)
  end)
end)
