describe("config.services", function()
  local services = require("config.services")

  describe("top-level tables", function()
    it("exposes lsp", function()
      assert.is_true(type(services.lsp) == "table")
    end)

    it("exposes dap", function()
      assert.is_true(type(services.dap) == "table")
    end)

    it("exposes linter", function()
      assert.is_true(type(services.linter) == "table")
    end)

    it("exposes formatter", function()
      assert.is_true(type(services.formatter) == "table")
    end)

    it("exposes formatter_defaults", function()
      assert.is_true(type(services.formatter_defaults) == "table")
    end)

    it("exposes linter_defaults", function()
      assert.is_true(type(services.linter_defaults) == "table")
    end)
  end)

  describe("lsp entries", function()
    it("each entry has a mason field (string or nil)", function()
      for name, meta in pairs(services.lsp) do
        assert.is_true(
          meta.mason == nil or type(meta.mason) == "string",
          name .. ".mason must be string or nil"
        )
      end
    end)

    it("each entry has a non-empty ft array", function()
      for name, meta in pairs(services.lsp) do
        assert.is_not_nil(meta.ft, name .. ".ft must exist")
        assert.is_true(type(meta.ft) == "table", name .. ".ft must be a table")
        assert.is_true(#meta.ft > 0, name .. ".ft must be non-empty")
      end
    end)

    it("each ft value is a string", function()
      for name, meta in pairs(services.lsp) do
        for _, ft in ipairs(meta.ft) do
          assert.is_true(
            type(ft) == "string",
            name .. " ft entry must be a string"
          )
        end
      end
    end)

    it("contains lua_ls pointing at lua", function()
      assert.is_not_nil(services.lsp.lua_ls)
      assert.is_true(vim.tbl_contains(services.lsp.lua_ls.ft, "lua"))
    end)

    it("contains pyright pointing at python", function()
      assert.is_not_nil(services.lsp.pyright)
      assert.is_true(vim.tbl_contains(services.lsp.pyright.ft, "python"))
    end)

    it("contains jsonls pointing at json", function()
      assert.is_not_nil(services.lsp.jsonls)
      assert.is_true(vim.tbl_contains(services.lsp.jsonls.ft, "json"))
    end)
  end)

  describe("dap entries", function()
    it("each entry has a non-empty ft array", function()
      for name, meta in pairs(services.dap) do
        assert.is_not_nil(meta.ft, name .. ".ft must exist")
        assert.is_true(#meta.ft > 0, name .. ".ft must be non-empty")
      end
    end)

    it("contains coreclr for C#", function()
      assert.is_not_nil(services.dap.coreclr)
      assert.is_true(vim.tbl_contains(services.dap.coreclr.ft, "cs"))
    end)

    it("contains python adapter", function()
      assert.is_not_nil(services.dap.python)
    end)
  end)

  describe("linter entries", function()
    it("each entry has a mason field (string)", function()
      for name, meta in pairs(services.linter) do
        assert.is_true(
          type(meta.mason) == "string",
          name .. ".mason must be a string"
        )
      end
    end)

    it("each entry has a non-empty ft array", function()
      for name, meta in pairs(services.linter) do
        assert.is_true(#meta.ft > 0, name .. ".ft must be non-empty")
      end
    end)

    it("contains luacheck for lua", function()
      assert.is_not_nil(services.linter.luacheck)
      assert.is_true(vim.tbl_contains(services.linter.luacheck.ft, "lua"))
    end)

    it("contains sqlfluff for sql filetypes", function()
      assert.is_not_nil(services.linter.sqlfluff)
      assert.is_true(vim.tbl_contains(services.linter.sqlfluff.ft, "sql"))
    end)
  end)

  describe("formatter entries", function()
    it("each entry has a non-empty ft array", function()
      for name, meta in pairs(services.formatter) do
        assert.is_true(#meta.ft > 0, name .. ".ft must be non-empty")
      end
    end)

    it("contains stylua for lua", function()
      assert.is_not_nil(services.formatter.stylua)
      assert.equals("lua", services.formatter.stylua.ft[1])
      assert.equals("stylua", services.formatter.stylua.mason)
    end)

    it(
      "ruff_fix / ruff_format / ruff_organize_imports all map to ruff mason pkg",
      function()
        assert.equals("ruff", services.formatter.ruff_fix.mason)
        assert.equals("ruff", services.formatter.ruff_format.mason)
        assert.equals("ruff", services.formatter.ruff_organize_imports.mason)
      end
    )

    it("prisma_fmt has no mason package (uses node_modules)", function()
      assert.is_not_nil(services.formatter.prisma_fmt)
      assert.is_nil(services.formatter.prisma_fmt.mason)
    end)
  end)

  describe("formatter_defaults", function()
    it("python order starts with ruff_fix", function()
      assert.is_not_nil(services.formatter_defaults.python)
      assert.equals("ruff_fix", services.formatter_defaults.python[1])
    end)

    it("python order contains ruff_organize_imports", function()
      assert.is_true(
        vim.tbl_contains(
          services.formatter_defaults.python,
          "ruff_organize_imports"
        )
      )
    end)

    it("python order contains ruff_format", function()
      assert.is_true(
        vim.tbl_contains(services.formatter_defaults.python, "ruff_format")
      )
    end)

    it(
      "every formatter referenced in defaults exists in the formatter table",
      function()
        for ft, order in pairs(services.formatter_defaults) do
          for _, name in ipairs(order) do
            assert.is_not_nil(
              services.formatter[name],
              name
                .. " in formatter_defaults["
                .. ft
                .. "] is missing from services.formatter"
            )
          end
        end
      end
    )

    it("markdown order contains deno_fmt", function()
      if services.formatter_defaults.markdown then
        assert.is_true(
          vim.tbl_contains(services.formatter_defaults.markdown, "deno_fmt")
        )
      end
    end)
  end)
end)
