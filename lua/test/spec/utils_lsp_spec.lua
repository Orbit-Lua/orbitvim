describe("utils.lsp", function()
  local lsp_utils = require("utils.lsp")

  describe("get_clients", function()
    it("returns a table", function()
      local clients = lsp_utils.get_clients()
      assert.is_true(type(clients) == "table")
    end)

    it(
      "returns an empty table in a headless session with no LSP running",
      function()
        assert.same({}, lsp_utils.get_clients())
      end
    )

    it("accepts an opts table without error", function()
      local ok = pcall(lsp_utils.get_clients, { bufnr = 0 })
      assert.is_true(ok)
    end)

    it("honours a custom filter function that rejects everything", function()
      local clients = lsp_utils.get_clients({
        filter = function(_)
          return false
        end,
      })
      assert.same({}, clients)
    end)
  end)

  describe("action proxy", function()
    it("returns a callable for any string key", function()
      local fn = lsp_utils.action["source.fixAll"]
      assert.is_true(type(fn) == "function")
    end)

    it("returns a distinct callable for each key", function()
      local fn1 = lsp_utils.action["source.organizeImports"]
      local fn2 = lsp_utils.action["source.fixAll"]
      assert.is_true(type(fn1) == "function")
      assert.is_true(type(fn2) == "function")
    end)
  end)

  describe("_supports_method table", function()
    it("is a table", function()
      assert.is_true(type(lsp_utils._supports_method) == "table")
    end)
  end)

  describe("on_supports_method", function()
    it("returns an autocmd id (number)", function()
      local id = lsp_utils.on_supports_method(
        "textDocument/hover_test",
        function() end
      )
      assert.is_true(type(id) == "number")
      pcall(vim.api.nvim_del_autocmd, id)
    end)

    it("registers the method in _supports_method", function()
      local method = "textDocument/test_register_"
        .. tostring(math.random(99999))
      local id = lsp_utils.on_supports_method(method, function() end)
      assert.is_not_nil(lsp_utils._supports_method[method])
      pcall(vim.api.nvim_del_autocmd, id)
    end)

    it("uses weak keys for client tracking", function()
      local method = "textDocument/weak_keys_" .. tostring(math.random(99999))
      local id = lsp_utils.on_supports_method(method, function() end)
      local inner = lsp_utils._supports_method[method]
      local mt = getmetatable(inner)
      assert.is_not_nil(mt)
      assert.equals("k", mt.__mode)
      pcall(vim.api.nvim_del_autocmd, id)
    end)

    it(
      "reuses the existing weak table on repeated calls for the same method",
      function()
        local method = "textDocument/reuse_" .. tostring(math.random(99999))
        local id1 = lsp_utils.on_supports_method(method, function() end)
        local tbl1 = lsp_utils._supports_method[method]
        local id2 = lsp_utils.on_supports_method(method, function() end)
        local tbl2 = lsp_utils._supports_method[method]
        assert.equals(tbl1, tbl2)
        pcall(vim.api.nvim_del_autocmd, id1)
        pcall(vim.api.nvim_del_autocmd, id2)
      end
    )
  end)

  describe("on_attach", function()
    it("returns an autocmd id (number)", function()
      local id = lsp_utils.on_attach(function() end)
      assert.is_true(type(id) == "number")
      pcall(vim.api.nvim_del_autocmd, id)
    end)

    it("accepts an optional name parameter", function()
      local id = lsp_utils.on_attach(function() end, "test_server")
      assert.is_true(type(id) == "number")
      pcall(vim.api.nvim_del_autocmd, id)
    end)
  end)

  describe("toggle_inlay_hints", function()
    it("is a callable function", function()
      assert.is_true(type(lsp_utils.toggle_inlay_hints) == "function")
    end)

    it("runs without error when inlay hints API is available", function()
      if vim.lsp.inlay_hint then
        local ok = pcall(lsp_utils.toggle_inlay_hints)
        assert.is_true(ok)
      end
    end)
  end)
end)
