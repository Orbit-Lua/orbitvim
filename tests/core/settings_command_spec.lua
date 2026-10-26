describe("settings command", function()
  local test = require("tests.helpers")

  after_each(function()
    pcall(vim.api.nvim_del_user_command, "OrbitSettings")
  end)

  it(
    "copies legacy bytes to writable storage and observes the destination",
    function()
      vim.g.orbitvim_settings_path = nil
      local settings = require("config.settings")
      local legacy, destination = settings.legacy_path(), settings.edit_path()
      test.write_file(legacy, '{"editor":{"shiftwidth":4}}')
      assert.equals(legacy, settings.path())
      require("core.settings").setup()
      assert.is_nil(vim.uv.fs_stat(destination))
      require("commands.settings").setup()
      vim.cmd.OrbitSettings()
      assert.equals(destination, settings.path())
      test.assert_path(destination, vim.api.nvim_buf_get_name(0))
      assert.same(
        vim.fn.readfile(legacy, "b"),
        vim.fn.readfile(destination, "b")
      )
      test.write_file(destination, '{"editor":{"shiftwidth":6}}')
      vim.api.nvim_exec_autocmds("BufWritePost", { pattern = destination })
      assert.equals(6, require("core.settings").info().values.editor.shiftwidth)
      test.write_file(legacy, '{"editor":{"shiftwidth":8}}')
      vim.api.nvim_exec_autocmds("BufWritePost", { pattern = legacy })
      assert.equals(6, require("core.settings").info().values.editor.shiftwidth)
      test.write_file(destination, "{invalid")
      assert.is_nil(settings.read())
      vim.cmd.OrbitSettings()
      assert.same({ "{invalid" }, vim.fn.readfile(destination))
    end
  )

  it("publishes without replacing a concurrent settings creator", function()
    local path = test.temp_dir("exclusive settings") .. "/settings.json"
    local fs = require("utils.fs")
    assert.is_true(fs.atomic_write(path, "first", { exclusive = true }))
    local ok, _, code = fs.atomic_write(path, "second", { exclusive = true })
    assert.is_false(ok)
    assert.equals("EEXIST", code)
    assert.same({ "first" }, vim.fn.readfile(path))
  end)

  it(
    "opens a schema-linked file through its mapping and preserves existing contents",
    function()
      vim.g.mapleader = " "
      vim.g.orbitvim_settings_path = test.temp_dir("settings command")
        .. "/settings.json"
      require("commands.settings").setup()
      require("core.keymaps")
      local mapping = vim.fn.maparg("<leader>uc", "n", false, true)
      vim.cmd(mapping.rhs:match("<cmd>(.-)<[cC][rR]>"))
      test.assert_path(
        vim.g.orbitvim_settings_path,
        vim.api.nvim_buf_get_name(0)
      )
      local decoded = vim.json.decode(
        table.concat(vim.fn.readfile(vim.g.orbitvim_settings_path), "\n")
      )
      assert.equals(
        vim.uri_from_fname(require("config.settings").schema_path),
        decoded["$schema"]
      )
      test.write_file(vim.g.orbitvim_settings_path, "{broken")
      vim.cmd("edit!")
      require("core.settings").setup()
      assert.is_truthy(require("core.settings").info().error)
      vim.cmd.OrbitSettings()
      assert.equals("{broken", vim.api.nvim_get_current_line())
    end
  )
end)
