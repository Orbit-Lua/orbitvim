describe("core.keymaps", function()
  local test = require("tests.helpers")
  local project = require("utils.project")
  local original_mapleader
  local original_cwd
  local original_fs_root
  local original_get_clients
  local original_core_keymaps
  local original_runtime_keymaps

  before_each(function()
    original_mapleader = vim.g.mapleader
    original_cwd = vim.fn.getcwd()
    original_fs_root = project.get_root
    original_get_clients = vim.lsp.get_clients
    original_core_keymaps = package.loaded["core.keymaps"]
    original_runtime_keymaps = package.loaded["features.lsp.runtime.keymaps"]
  end)

  after_each(function()
    vim.g.mapleader = original_mapleader
    vim.api.nvim_set_current_dir(original_cwd)
    project.get_root = original_fs_root
    vim.lsp.get_clients = original_get_clients
    package.loaded["core.keymaps"] = original_core_keymaps
    package.loaded["features.lsp.runtime.keymaps"] = original_runtime_keymaps
    test.cleanup_all()
  end)

  it("<leader>fd changes cwd to roots containing spaces", function()
    local root = test.temp_dir("root with space")
    vim.g.mapleader = " "
    package.loaded["core.keymaps"] = nil
    require("core.keymaps")

    project.get_root = function()
      return root
    end

    local mapping = vim.fn.maparg("<leader>fd", "n", false, true)
    assert.equals("function", type(mapping.callback))

    mapping.callback()
    assert.equals(vim.fs.normalize(root), vim.fs.normalize(vim.fn.getcwd()))
  end)

  it("prevents K from falling back to unrelated help", function()
    local original_win = vim.api.nvim_get_current_win()
    local original_buf = vim.api.nvim_get_current_buf()
    local buf = vim.api.nvim_create_buf(false, true)
    local existing_windows = {}

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      existing_windows[win] = true
    end

    vim.g.mapleader = " "
    package.loaded["core.keymaps"] = nil
    require("core.keymaps")
    vim.api.nvim_win_set_buf(original_win, buf)
    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      { "OPEN SYMMETRIC KEY DemoKey;" }
    )
    vim.api.nvim_set_option_value("filetype", "sql", { buf = buf })
    vim.api.nvim_win_set_cursor(original_win, { 1, 0 })

    vim.api.nvim_feedkeys("K", "x", false)

    local unexpected = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if not existing_windows[win] then
        local win_buf = vim.api.nvim_win_get_buf(win)
        table.insert(unexpected, vim.bo[win_buf].filetype)
        vim.api.nvim_win_close(win, true)
      end
    end

    vim.api.nvim_win_set_buf(original_win, original_buf)
    vim.api.nvim_buf_delete(buf, { force = true })
    assert.same({}, unexpected)
  end)

  it(
    "resolves dynamic hover against the requested buffer rather than the current one",
    function()
      local source, current =
        vim.api.nvim_create_buf(true, false),
        vim.api.nvim_create_buf(true, false)
      vim.bo[source].filetype, vim.bo[current].filetype = "python", "lua"
      vim.api.nvim_set_current_buf(current)
      local client = setmetatable({
        server_capabilities = {},
        capabilities = {
          textDocument = { hover = { dynamicRegistration = true } },
        },
        registrations = {
          hoverProvider = {
            {
              method = "textDocument/hover",
              registerOptions = {
                documentSelector = { { language = "python" } },
              },
            },
          },
        },
        get_language_id = function(_, filetype)
          return filetype
        end,
      }, { __index = require("vim.lsp.client") })
      vim.lsp.get_clients = function(opts)
        assert.is_table(opts)
        return { client }
      end
      package.loaded["features.lsp.runtime.keymaps"] = nil
      local keymaps = require("features.lsp.runtime.keymaps")

      assert.is_true(keymaps.has(source, "hover"))
      assert.is_false(keymaps.has(current, "hover"))
    end
  )

  it("lets attached server keys replace or remove defaults per mode", function()
    local buffer = vim.api.nvim_create_buf(true, false)
    local original_config = package.loaded["features.lsp.config"]
    local original_snacks = package.loaded.snacks
    package.loaded.snacks = {
      words = {
        is_enabled = function()
          return false
        end,
      },
    }
    vim.g.mapleader = " "
    local server_definition = function() end
    package.loaded["features.lsp.config"] = {
      servers = {
        probe = {
          keys = {
            { "gd", server_definition, desc = "server definition" },
            { "gR", false },
            { "<leader>ca", false, mode = "v" },
          },
        },
      },
    }
    vim.lsp.get_clients = function()
      return {
        {
          name = "probe",
          supports_method = function()
            return true
          end,
        },
      }
    end
    package.loaded["features.lsp.runtime.keymaps"] = nil

    local ok, err = pcall(function()
      require("features.lsp.runtime.keymaps").on_attach(nil, buffer)
      local function mapping(mode, lhs)
        return vim.api.nvim_buf_call(buffer, function()
          return vim.fn.maparg(lhs, mode, false, true)
        end)
      end
      assert.equals(server_definition, mapping("n", "gd").callback)
      assert.same({}, mapping("n", "gR"))
      assert.equals("code action", mapping("n", " ca").desc)
      assert.same({}, mapping("v", " ca"))
    end)
    package.loaded["features.lsp.config"] = original_config
    package.loaded.snacks = original_snacks
    vim.api.nvim_buf_delete(buffer, { force = true })
    assert(ok, err)
  end)

  it("toggles code lenses for the current buffer that enabled them", function()
    local buffer = vim.api.nvim_create_buf(true, false)
    local original_config = package.loaded["features.lsp.config"]
    package.loaded["features.lsp.config"] = { servers = {} }
    vim.g.mapleader = " "
    vim.lsp.get_clients = function()
      return {
        {
          name = "probe",
          supports_method = function(_, method)
            return method == "textDocument/codeLens"
          end,
        },
      }
    end
    package.loaded["features.lsp.runtime.keymaps"] = nil

    local ok, err = pcall(function()
      vim.api.nvim_set_current_buf(buffer)
      require("features.lsp.runtime.keymaps").on_attach(nil, buffer)
      vim.lsp.get_clients = original_get_clients
      vim.lsp.codelens.enable(true, { bufnr = buffer })
      vim.fn.maparg(" cc", "n", false, true).callback()
      assert.is_false(vim.lsp.codelens.is_enabled({ bufnr = buffer }))
    end)
    package.loaded["features.lsp.config"] = original_config
    vim.api.nvim_buf_delete(buffer, { force = true })
    assert(ok, err)
  end)
end)
