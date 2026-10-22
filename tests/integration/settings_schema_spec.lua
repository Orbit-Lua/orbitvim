describe("settings schema language server", function()
  local test = require("tests.helpers")
  local client, buffer

  after_each(function()
    if client then
      client:stop(true)
      vim.wait(3000, function()
        return client:is_stopped()
      end, 10)
    end
    if buffer and vim.api.nvim_buf_is_valid(buffer) then
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
  end)

  it(
    "offers policy values and diagnoses invalid settings through the actual JSON server",
    function()
      local executable = vim.fn.exepath("vscode-json-language-server")
      if executable == "" then
        executable = vim.g.orbitvim_test_plugin_data_path
          .. "/mason/bin/vscode-json-language-server"
          .. (package.config:sub(1, 1) == "\\" and ".cmd" or "")
      end
      assert.equals(
        1,
        vim.fn.executable(executable),
        "json-lsp is required for schema integration tests"
      )
      local root = test.temp_dir("settings-schema")
      local filename = root .. "/settings.json"
      vim.g.orbitvim_settings_path = filename
      local lines = {
        "{",
        '  "editor": {},',
        '  "tool_manager": { "missing_package_policy": "" }',
        "}",
      }
      test.write_file(filename, lines)
      buffer = vim.fn.bufadd(filename)
      vim.fn.bufload(buffer)
      vim.bo[buffer].filetype = "json"
      local id = assert(vim.lsp.start({
        name = "orbitvim-schema-test",
        cmd = { executable, "--stdio" },
        root_dir = root,
        settings = (require("config.lsp").servers.jsonls or {}).settings,
        capabilities = require("config.lsp.capabilities").get_lsp_capabilities(
          {},
          true
        ),
        init_options = {
          provideFormatter = false,
          handledSchemaProtocols = { "file" },
        },
      }, { bufnr = buffer }))
      client = assert(vim.lsp.get_client_by_id(id))
      assert.is_true(vim.wait(10000, function()
        return client.initialized
      end, 20))
      local response, err = client:request_sync("textDocument/completion", {
        textDocument = { uri = vim.uri_from_fname(filename) },
        position = {
          line = 2,
          character = assert(lines[3]:find('""', 1, true)),
        },
      }, 10000, buffer)
      assert.is_not_nil(response, vim.inspect(err))
      assert.is_nil(response.err)
      local labels = {}
      for _, item in ipairs(response.result.items or response.result) do
        labels[item.label:gsub('"', "")] = true
      end
      assert.is_true(labels.auto, vim.inspect(response.result))
      assert.is_true(labels.manual)
      lines[3] = '  "tool_manager": { "width": 0 }'
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
      local diagnostics =
        assert(client:request_sync("textDocument/diagnostic", {
          textDocument = { uri = vim.uri_from_fname(filename) },
        }, 10000, buffer))
      local rejected = false
      for _, diagnostic in ipairs(diagnostics.result.items) do
        rejected = rejected
          or (
            diagnostic.range.start.line == 2
            and diagnostic.message:find("24", 1, true) ~= nil
          )
      end
      assert.is_true(rejected, vim.inspect(diagnostics))
    end
  )
end)
