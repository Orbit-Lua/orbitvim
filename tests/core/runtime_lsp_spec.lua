describe("LSP server registration", function()
  local original_config, original_enable, original_clients, original_hint_enable, original_hint_state

  before_each(function()
    original_config, original_enable = vim.lsp.config, vim.lsp.enable
    original_clients = vim.lsp.get_clients
    original_hint_enable, original_hint_state =
      vim.lsp.inlay_hint.enable, vim.lsp.inlay_hint.is_enabled
    package.loaded["core.theme"] = { load_cache = function() end }
    package.loaded["tool.state"] = {
      is_enabled = function()
        return true
      end,
    }
    package.loaded["config.packages"] = { lsp_servers = { "yamlls" } }
  end)

  it(
    "replaces the Ruff attachment subscription during repeated setup",
    function()
      local setup = require("config.lsp.servers.python").setup.ruff
      setup()
      setup()
      local writes = 0
      local client = {
        name = "ruff",
        server_capabilities = setmetatable({}, {
          __newindex = function(_, key, value)
            assert.equals("hoverProvider", key)
            assert.is_false(value)
            writes = writes + 1
          end,
        }),
      }
      local get_client = vim.lsp.get_client_by_id
      vim.lsp.get_client_by_id = function()
        return client
      end
      local ok, err = pcall(vim.api.nvim_exec_autocmds, "LspAttach", {
        buffer = 0,
        data = { client_id = 888 },
      })
      vim.lsp.get_client_by_id = get_client
      assert(ok, err)
      assert.equals(1, writes)
    end
  )

  after_each(function()
    vim.lsp.config, vim.lsp.enable = original_config, original_enable
    vim.lsp.get_clients = original_clients
    vim.lsp.inlay_hint.enable, vim.lsp.inlay_hint.is_enabled =
      original_hint_enable, original_hint_state
  end)

  it(
    "installs diagnostic filtering once and invalidates detached refreshes",
    function()
      local runtime = require("runtime.lsp")
      runtime.install_diagnostic_filter()
      local handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
      runtime.install_diagnostic_filter()
      assert.equals(
        handler,
        vim.lsp.handlers["textDocument/publishDiagnostics"]
      )
      local buffer = vim.api.nvim_create_buf(true, false)
      local client = { id = 777, attached_buffers = { [buffer] = true } }
      local original_client, defer = vim.lsp.get_client_by_id, vim.defer_fn
      local refreshes, queued = 0, {}
      vim.lsp.get_client_by_id = function()
        return client
      end
      vim.defer_fn = function(callback)
        table.insert(queued, callback)
      end
      local owner = require("runtime.lsp.client")
      local refresh = owner.refresh_supported_methods
      owner.refresh_supported_methods = function()
        refreshes = refreshes + 1
      end
      local ok, err = pcall(function()
        runtime.activate_features({
          inlay_hints = { enabled = false, exclude = {} },
          codelens = { enabled = false },
        })
        vim.api.nvim_exec_autocmds(
          "LspProgress",
          { pattern = "end", data = { client_id = client.id } }
        )
        vim.api.nvim_exec_autocmds(
          "LspDetach",
          { buffer = buffer, data = { client_id = client.id } }
        )
        for _, callback in ipairs(queued) do
          callback()
        end
        assert.equals(0, refreshes)
      end)
      vim.lsp.get_client_by_id, vim.defer_fn = original_client, defer
      owner.refresh_supported_methods = refresh
      assert(ok, err)
    end
  )

  it(
    "registers the configured YAML schema associations before enabling",
    function()
      local registered, configured_before_enable
      vim.lsp.config = function(name, options)
        assert.equals("yamlls", name)
        registered = options
      end
      vim.lsp.enable = function()
        configured_before_enable = registered ~= nil
      end
      require("runtime.lsp").register_servers({
        servers = require("config.lsp.servers.markup").servers,
        setup = {},
        disable_default_settings = {},
      })
      assert.is_not_nil(registered.settings)
      assert.is_true(configured_before_enable)
      assert.is_true(registered.settings.yaml.completion)
      local uri = "https://gitlab.com/gitlab-org/gitlab/-/raw/master/"
        .. "app/assets/javascripts/editor/schema/ci.json"
      assert.same({
        ".gitlab-ci.yml",
        ".gitlab-ci.yaml",
        ".gitlab/ci/*.yml",
        ".gitlab/ci/*.yaml",
      }, registered.settings.yaml.schemas[uri])
    end
  )
  it(
    "applies hint exclusions and restores previous hints if a backend update fails",
    function()
      local a, b =
        vim.api.nvim_create_buf(true, false),
        vim.api.nvim_create_buf(true, false)
      vim.bo[a].filetype, vim.bo[b].filetype = "lua", "help"
      local enabled, refuse = { [a] = false, [b] = false }, false
      vim.lsp.get_clients = function()
        return {
          {
            attached_buffers = { [a] = true, [b] = true },
            supports_method = function()
              return true
            end,
          },
        }
      end
      vim.lsp.inlay_hint.is_enabled = function(opts)
        return enabled[opts.bufnr]
      end
      vim.lsp.inlay_hint.enable = function(value, opts)
        if refuse and opts.bufnr == b then
          error("hint update refused")
        end
        enabled[opts.bufnr] = value
      end
      local runtime = require("runtime.lsp")
      runtime.apply_inlay_hints({ enabled = true, exclude = { "help" } })
      assert.is_true(enabled[a])
      assert.is_false(enabled[b])
      runtime.apply_inlay_hints({ enabled = false, exclude = {} })
      refuse = true
      local ok, err = pcall(function()
        runtime.apply_inlay_hints({ enabled = true, exclude = {} })
      end)
      assert.is_false(ok)
      assert.matches("hint update refused", err)
      assert.matches("rollback failed", err)
      assert.matches("restart required", err)
      assert.is_false(enabled[a])
      assert.is_false(enabled[b])
    end
  )
end)
