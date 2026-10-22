describe("core.keymaps", function()
  local test = require("tests.helpers")
  local fs = require("utils.fs")
  local lsp_client = require("runtime.lsp.client")
  local original_mapleader
  local original_cwd
  local original_fs_root
  local original_get_clients
  local original_core_keymaps
  local original_runtime_keymaps

  before_each(function()
    original_mapleader = vim.g.mapleader
    original_cwd = vim.fn.getcwd()
    original_fs_root = fs.get_root
    original_get_clients = lsp_client.get_clients
    original_core_keymaps = package.loaded["core.keymaps"]
    original_runtime_keymaps = package.loaded["runtime.lsp.keymaps"]
  end)

  after_each(function()
    vim.g.mapleader = original_mapleader
    vim.api.nvim_set_current_dir(original_cwd)
    fs.get_root = original_fs_root
    lsp_client.get_clients = original_get_clients
    package.loaded["core.keymaps"] = original_core_keymaps
    package.loaded["runtime.lsp.keymaps"] = original_runtime_keymaps
    test.cleanup_all()
  end)

  it("<leader>fd changes cwd to roots containing spaces", function()
    local root = test.temp_dir("root with space")
    vim.g.mapleader = " "
    package.loaded["core.keymaps"] = nil
    require("core.keymaps")

    fs.get_root = function()
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
      lsp_client.get_clients = function(opts)
        assert.is_table(opts)
        return { client }
      end
      package.loaded["runtime.lsp.keymaps"] = nil
      local keymaps = require("runtime.lsp.keymaps")

      assert.is_true(keymaps.has(source, "hover"))
      assert.is_false(keymaps.has(current, "hover"))
    end
  )
end)
