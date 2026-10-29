describe("settings schema language server", function()
  local test = require("tests.helpers")
  local client, buffer

  after_each(function()
    pcall(vim.api.nvim_del_user_command, "OrbitSettings")
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
      require("features.settings.commands").setup()
      vim.cmd.OrbitSettings()
      local created =
        vim.json.decode(table.concat(vim.fn.readfile(filename), "\n"))
      local schema_reference = assert(created["$schema"])
      buffer = vim.api.nvim_get_current_buf()
      vim.bo[buffer].filetype = "json"
      -- Keep manual pull requests separate from current-buffer auto pulls.
      vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(false, true))
      local id = assert(vim.lsp.start({
        name = "orbitvim-schema-test",
        cmd = { executable, "--stdio" },
        root_dir = root,
        settings = (require("features.lsp.config").servers.jsonls or {}).settings,
        capabilities = require("features.lsp.runtime").client_capabilities(),
        init_options = {
          provideFormatter = false,
          handledSchemaProtocols = { "file" },
        },
      }, { bufnr = buffer }))
      client = assert(vim.lsp.get_client_by_id(id))
      assert.is_true(vim.wait(10000, function()
        return client.initialized
      end, 20))
      for _, linked in ipairs({ false, true }) do
        local lines = {
          "{",
          '  "editor": {},',
          '  "hangar": { "missing_package_policy": "" }',
          "}",
        }
        local row = 2
        if linked then
          table.insert(
            lines,
            2,
            '  "$schema": ' .. vim.json.encode(schema_reference) .. ","
          )
          row = row + 1
        end
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
        local response, err = client:request_sync("textDocument/completion", {
          textDocument = { uri = vim.uri_from_fname(filename) },
          position = {
            line = row,
            character = assert(lines[row + 1]:find('""', 1, true)),
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
        lines[row + 1] = '  "hangar": { "width": 0 }'
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
        local diagnostics =
          assert(client:request_sync("textDocument/diagnostic", {
            textDocument = { uri = vim.uri_from_fname(filename) },
          }, 10000, buffer))
        local rejected = false
        for _, diagnostic in ipairs(diagnostics.result.items) do
          rejected = rejected
            or (
              diagnostic.range.start.line == row
              and diagnostic.message:lower():find("minimum", 1, true) ~= nil
            )
        end
        assert.is_true(rejected, vim.inspect(diagnostics))
      end
    end
  )
end)
