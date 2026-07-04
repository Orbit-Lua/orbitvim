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

  describe("refresh_supported_methods", function()
    it("is a callable function", function()
      assert.is_true(type(lsp_utils.refresh_supported_methods) == "function")
    end)

    it("does not replay callbacks unless they opt in to refresh", function()
      local method = "textDocument/refresh_" .. tostring(math.random(99999))
      local bufnr = vim.api.nvim_get_current_buf()
      local client = {
        id = 123456,
        supports_method = function(_, checked_method, checked_buffer)
          return checked_method == method and checked_buffer == bufnr
        end,
      }
      local calls = 0
      local get_client_by_id = vim.lsp.get_client_by_id
      vim.lsp.get_client_by_id = function(id)
        return id == client.id and client or get_client_by_id(id)
      end

      local events = {}
      local id = lsp_utils.on_supports_method(method, function(_, buffer, event)
        if buffer == bufnr then
          calls = calls + 1
          table.insert(events, event)
        end
      end)

      lsp_utils._check_methods(client, bufnr)
      lsp_utils._check_methods(client, bufnr)
      lsp_utils.refresh_supported_methods(client, bufnr)

      assert.equals(1, calls)
      assert.is_nil(events[1].refresh)

      vim.lsp.get_client_by_id = get_client_by_id
      lsp_utils._supports_method[method] = nil
      lsp_utils._refresh_methods[method] = nil
      pcall(vim.api.nvim_del_autocmd, id)
    end)

    it("replays refreshable support-method callbacks", function()
      local method = "textDocument/refreshable_" .. tostring(math.random(99999))
      local bufnr = vim.api.nvim_get_current_buf()
      local client = {
        id = 123457,
        supports_method = function(_, checked_method, checked_buffer)
          return checked_method == method and checked_buffer == bufnr
        end,
      }
      local calls = 0
      local get_client_by_id = vim.lsp.get_client_by_id
      vim.lsp.get_client_by_id = function(id)
        return id == client.id and client or get_client_by_id(id)
      end

      local events = {}
      local id = lsp_utils.on_supports_method(method, function(_, buffer, event)
        if buffer == bufnr then
          calls = calls + 1
          table.insert(events, event)
        end
      end, { refresh = true })

      lsp_utils._check_methods(client, bufnr)
      lsp_utils._check_methods(client, bufnr)
      lsp_utils.refresh_supported_methods(client, bufnr)

      assert.equals(2, calls)
      assert.is_nil(events[1].refresh)
      assert.is_true(events[2].refresh)

      vim.lsp.get_client_by_id = get_client_by_id
      lsp_utils._supports_method[method] = nil
      lsp_utils._refresh_methods[method] = nil
      pcall(vim.api.nvim_del_autocmd, id)
    end)

    it(
      "replays only refreshable callbacks when callbacks share a method",
      function()
        local method = "textDocument/shared_refresh_"
          .. tostring(math.random(99999))
        local bufnr = vim.api.nvim_get_current_buf()
        local client = {
          id = 123458,
          supports_method = function(_, checked_method, checked_buffer)
            return checked_method == method and checked_buffer == bufnr
          end,
        }
        local normal_calls = 0
        local refreshable_calls = 0
        local get_client_by_id = vim.lsp.get_client_by_id
        vim.lsp.get_client_by_id = function(id)
          return id == client.id and client or get_client_by_id(id)
        end

        local normal_id = lsp_utils.on_supports_method(
          method,
          function(_, buffer)
            if buffer == bufnr then
              normal_calls = normal_calls + 1
            end
          end
        )
        local refreshable_id = lsp_utils.on_supports_method(
          method,
          function(_, buffer)
            if buffer == bufnr then
              refreshable_calls = refreshable_calls + 1
            end
          end,
          { refresh = true }
        )

        lsp_utils._check_methods(client, bufnr)
        lsp_utils.refresh_supported_methods(client, bufnr)

        assert.equals(1, normal_calls)
        assert.equals(2, refreshable_calls)

        vim.lsp.get_client_by_id = get_client_by_id
        lsp_utils._supports_method[method] = nil
        lsp_utils._refresh_methods[method] = nil
        pcall(vim.api.nvim_del_autocmd, normal_id)
        pcall(vim.api.nvim_del_autocmd, refreshable_id)
      end
    )
  end)
end)
