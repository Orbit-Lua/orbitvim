describe("config.packages", function()
  local packages = require("config.packages")
  local tools = require("config.tools")

  describe("lsp_servers", function()
    it("is a non-empty list", function()
      assert.is_true(type(packages.lsp_servers) == "table")
      assert.is_true(#packages.lsp_servers > 0)
    end)

    it("contains every LSP server name from tools.lsp", function()
      for name in pairs(tools.lsp) do
        assert.is_true(
          vim.tbl_contains(packages.lsp_servers, name),
          name .. " missing from lsp_servers"
        )
      end
    end)

    it("has no duplicate entries", function()
      local seen = {}
      for _, name in ipairs(packages.lsp_servers) do
        assert.is_nil(seen[name], "Duplicate lsp_server: " .. name)
        seen[name] = true
      end
    end)

    it("contains lua_ls", function()
      assert.is_true(vim.tbl_contains(packages.lsp_servers, "lua_ls"))
    end)

    it("contains pyright", function()
      assert.is_true(vim.tbl_contains(packages.lsp_servers, "pyright"))
    end)

    it("is sorted for deterministic startup output", function()
      local sorted = vim.deepcopy(packages.lsp_servers)
      table.sort(sorted)
      assert.same(sorted, packages.lsp_servers)
    end)
  end)

  describe("mason_ensure_installed", function()
    it("is a non-empty list", function()
      assert.is_true(type(packages.mason_ensure_installed) == "table")
      assert.is_true(#packages.mason_ensure_installed > 0)
    end)

    it("has no duplicate entries", function()
      local seen = {}
      for _, pkg in ipairs(packages.mason_ensure_installed) do
        assert.is_nil(seen[pkg], "Duplicate mason package: " .. pkg)
        seen[pkg] = true
      end
    end)

    it("contains mason packages from all lsp tools", function()
      for name, meta in pairs(tools.lsp) do
        if meta.mason then
          assert.is_true(
            vim.tbl_contains(packages.mason_ensure_installed, meta.mason),
            meta.mason
              .. " (from lsp."
              .. name
              .. ") missing from mason_ensure_installed"
          )
        end
      end
    end)

    it("contains mason packages from linter tools", function()
      for name, meta in pairs(tools.linter) do
        if meta.mason then
          assert.is_true(
            vim.tbl_contains(packages.mason_ensure_installed, meta.mason),
            meta.mason
              .. " (from linter."
              .. name
              .. ") missing from mason_ensure_installed"
          )
        end
      end
    end)

    it("contains mason packages from formatter tools", function()
      for name, meta in pairs(tools.formatter) do
        if meta.mason then
          assert.is_true(
            vim.tbl_contains(packages.mason_ensure_installed, meta.mason),
            meta.mason
              .. " (from formatter."
              .. name
              .. ") missing from mason_ensure_installed"
          )
        end
      end
    end)

    it("contains mason packages from dap tools", function()
      for name, meta in pairs(tools.dap) do
        if meta.mason then
          assert.is_true(
            vim.tbl_contains(packages.mason_ensure_installed, meta.mason),
            meta.mason
              .. " (from dap."
              .. name
              .. ") missing from mason_ensure_installed"
          )
        end
      end
    end)

    it("contains lua-language-server", function()
      assert.is_true(
        vim.tbl_contains(packages.mason_ensure_installed, "lua-language-server")
      )
    end)

    it("contains stylua", function()
      assert.is_true(
        vim.tbl_contains(packages.mason_ensure_installed, "stylua")
      )
    end)

    it("contains registry package dependencies", function()
      for name, definition in pairs(tools.package) do
        if definition.source == "mason" then
          assert.is_true(
            vim.tbl_contains(packages.mason_ensure_installed, name),
            name .. " missing from mason_ensure_installed"
          )
        end
      end
    end)

    it("is sorted for deterministic startup output", function()
      local sorted = vim.deepcopy(packages.mason_ensure_installed)
      table.sort(sorted)
      assert.same(sorted, packages.mason_ensure_installed)
    end)
  end)

  describe("treesitter_ensure_installed", function()
    it("is a non-empty list", function()
      assert.is_true(type(packages.treesitter_ensure_installed) == "table")
      assert.is_true(#packages.treesitter_ensure_installed > 0)
    end)

    it("contains lua", function()
      assert.is_true(
        vim.tbl_contains(packages.treesitter_ensure_installed, "lua")
      )
    end)

    it("contains python", function()
      assert.is_true(
        vim.tbl_contains(packages.treesitter_ensure_installed, "python")
      )
    end)

    it("contains typescript", function()
      assert.is_true(
        vim.tbl_contains(packages.treesitter_ensure_installed, "typescript")
      )
    end)

    it("contains javascript", function()
      assert.is_true(
        vim.tbl_contains(packages.treesitter_ensure_installed, "javascript")
      )
    end)

    it("contains markdown", function()
      assert.is_true(
        vim.tbl_contains(packages.treesitter_ensure_installed, "markdown")
      )
    end)

    it("has no duplicate entries", function()
      local seen = {}
      for _, lang in ipairs(packages.treesitter_ensure_installed) do
        assert.is_nil(seen[lang], "Duplicate treesitter parser: " .. lang)
        seen[lang] = true
      end
    end)

    it("is derived from the parser registry", function()
      local expected = vim.tbl_keys(tools.parser)
      table.sort(expected)
      assert.same(expected, packages.treesitter_ensure_installed)
    end)
  end)
end)
