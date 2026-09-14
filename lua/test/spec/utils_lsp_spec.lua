describe("utils.lsp", function()
  local lsp
  local autocmds
  local buffers
  local original_code_action
  local original_get_client_by_id
  local original_get_clients
  local original_inlay_enable
  local original_inlay_is_enabled

  before_each(function()
    package.loaded["utils.lsp"] = nil
    lsp = require("utils.lsp")
    autocmds = {}
    buffers = {}
    original_code_action = vim.lsp.buf.code_action
    original_get_client_by_id = vim.lsp.get_client_by_id
    original_get_clients = vim.lsp.get_clients
    original_inlay_enable = vim.lsp.inlay_hint.enable
    original_inlay_is_enabled = vim.lsp.inlay_hint.is_enabled
  end)

  after_each(function()
    for _, id in ipairs(autocmds) do
      pcall(vim.api.nvim_del_autocmd, id)
    end
    for _, buf in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    vim.lsp.buf.code_action = original_code_action
    vim.lsp.get_client_by_id = original_get_client_by_id
    vim.lsp.get_clients = original_get_clients
    vim.lsp.inlay_hint.enable = original_inlay_enable
    vim.lsp.inlay_hint.is_enabled = original_inlay_is_enabled
    package.loaded["utils.lsp"] = nil
  end)

  local function track_autocmd(id)
    table.insert(autocmds, id)
    return id
  end

  local function listed_buffer()
    local buf = vim.api.nvim_create_buf(true, false)
    table.insert(buffers, buf)
    return buf
  end

  it("filters the clients returned by Neovim", function()
    local received
    vim.lsp.get_clients = function(opts)
      received = opts
      return { { id = 1 }, { id = 2 } }
    end

    local clients = lsp.get_clients({
      bufnr = 7,
      filter = function(client)
        return client.id == 2
      end,
    })

    assert.equals(7, received.bufnr)
    assert.same(
      { 2 },
      vim.tbl_map(function(client)
        return client.id
      end, clients)
    )
  end)

  it("turns an action name into an applying code-action request", function()
    local received
    vim.lsp.buf.code_action = function(opts)
      received = opts
    end

    lsp.action["source.fixAll"]()

    assert.same({
      apply = true,
      context = {
        only = { "source.fixAll" },
        diagnostics = {},
      },
    }, received)
  end)

  it("runs named attach callbacks only for the matching client", function()
    local client = { id = 42, name = "lua_ls" }
    vim.lsp.get_client_by_id = function()
      return client
    end
    local calls = 0
    local buf = listed_buffer()
    track_autocmd(lsp.on_attach(function(_, attached_buf)
      calls = calls + 1
      assert.equals(buf, attached_buf)
    end, "roslyn"))

    vim.api.nvim_exec_autocmds("LspAttach", {
      buffer = buf,
      data = { client_id = client.id },
    })
    client.name = "roslyn"
    vim.api.nvim_exec_autocmds("LspAttach", {
      buffer = buf,
      data = { client_id = client.id },
    })

    assert.equals(1, calls)
  end)

  it("dispatches support callbacks only for their registered method", function()
    local client = { id = 43 }
    vim.lsp.get_client_by_id = function()
      return client
    end
    local calls = 0
    track_autocmd(
      lsp.on_supports_method(
        "textDocument/hover",
        function(received_client, buffer)
          calls = calls + 1
          assert.equals(client, received_client)
          assert.equals(9, buffer)
        end
      )
    )

    for _, method in ipairs({ "textDocument/definition", "textDocument/hover" }) do
      vim.api.nvim_exec_autocmds("User", {
        pattern = "LspSupportsMethod",
        data = { client_id = client.id, buffer = 9, method = method },
      })
    end

    assert.equals(1, calls)
  end)

  it("replays only callbacks that opt in to capability refreshes", function()
    local method = "textDocument/inlayHint"
    local buf = listed_buffer()
    local client = {
      id = 44,
      supports_method = function(_, checked_method, checked_buffer)
        return checked_method == method and checked_buffer == buf
      end,
    }
    vim.lsp.get_client_by_id = function()
      return client
    end

    local normal_calls = 0
    local refreshable_calls = 0
    track_autocmd(lsp.on_supports_method(method, function()
      normal_calls = normal_calls + 1
    end))
    track_autocmd(lsp.on_supports_method(method, function(_, _, event)
      refreshable_calls = refreshable_calls + 1
      if refreshable_calls == 1 then
        assert.is_nil(event.refresh)
      else
        assert.is_true(event.refresh)
      end
    end, { refresh = true }))

    lsp._check_methods(client, buf)
    lsp.refresh_supported_methods(client, buf)

    assert.equals(1, normal_calls)
    assert.equals(2, refreshable_calls)
  end)

  it("toggles inlay hints from their current state", function()
    local enabled
    vim.lsp.inlay_hint.is_enabled = function()
      return true
    end
    vim.lsp.inlay_hint.enable = function(value)
      enabled = value
    end

    lsp.toggle_inlay_hints()

    assert.is_false(enabled)
  end)
end)
