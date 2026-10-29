describe("LSP server registration", function()
  local original_config, original_enable, original_clients, original_hint_enable, original_hint_state
  local original_diagnostics

  before_each(function()
    original_config, original_enable = vim.lsp.config, vim.lsp.enable
    original_clients = vim.lsp.get_clients
    original_diagnostics = vim.lsp.handlers["textDocument/publishDiagnostics"]
    original_hint_enable, original_hint_state =
      vim.lsp.inlay_hint.enable, vim.lsp.inlay_hint.is_enabled
    package.loaded["features.theme.runtime"] = { load_cache = function() end }
    package.loaded["hangar.state"] = {
      is_enabled = function()
        return true
      end,
    }
    package.loaded["features.hangar.config.packages"] =
      { lsp_servers = { "yamlls" } }
  end)

  it(
    "replaces the Ruff attachment subscription during repeated setup",
    function()
      local setup = require("features.lsp.config.servers.python").setup.ruff
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
    vim.lsp.handlers["textDocument/publishDiagnostics"] = original_diagnostics
    vim.lsp.inlay_hint.enable, vim.lsp.inlay_hint.is_enabled =
      original_hint_enable, original_hint_state
  end)

  it(
    "disables semantic tokens without replacing Roslyn initialization",
    function()
      -- Use Neovim's config merge on a detached copy, without starting servers.
      vim.lsp.config = vim.deepcopy(original_config)
      vim.lsp.enable = function() end
      package.loaded["features.hangar.config.packages"] = {
        lsp_servers = { "lua_ls", "roslyn" },
      }
      local initialized = false
      local function roslyn_init()
        initialized = true
      end
      vim.lsp.config("roslyn", { on_init = roslyn_init })

      require("features.lsp.runtime").register_servers(
        require("features.lsp.config")
      )
      local client = {
        server_capabilities = {
          semanticTokensProvider = { full = true },
          hoverProvider = true,
        },
      }
      vim.lsp.config.lua_ls.on_init(client, {})
      assert.is_nil(client.server_capabilities.semanticTokensProvider)
      assert.is_true(client.server_capabilities.hoverProvider)

      assert.equals(roslyn_init, vim.lsp.config.roslyn.on_init)
      vim.lsp.config.roslyn.on_init(client, {})
      assert.is_true(initialized)
      client.server_capabilities.semanticTokensProvider = { full = true }
      vim.lsp.config.roslyn.on_attach(client, 0)
      assert.is_nil(client.server_capabilities.semanticTokensProvider)
      assert.is_true(client.server_capabilities.hoverProvider)
    end
  )

  it(
    "installs diagnostic filtering once and invalidates detached refreshes",
    function()
      local runtime = require("features.lsp.runtime")
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
      local owner = require("features.lsp.runtime.client")
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

  it("forwards supplied server settings before enabling", function()
    local registered
    local calls = {}
    local settings = {
      yaml = {
        completion = false,
        schemas = { ["file:///fixture-schema.json"] = { "fixture.yml" } },
      },
    }
    vim.lsp.config = function(name, options)
      assert.equals("yamlls", name)
      registered = options
      calls[#calls + 1] = "configure"
    end
    vim.lsp.enable = function()
      calls[#calls + 1] = "enable"
    end
    require("features.lsp.runtime").register_servers({
      servers = { yamlls = { settings = settings } },
      setup = {},
      disable_default_settings = {},
    })
    assert.same({ "configure", "enable" }, calls)
    assert.same(settings, registered.settings)
  end)
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
      local runtime = require("features.lsp.runtime")
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
