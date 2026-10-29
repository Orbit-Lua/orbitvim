describe("settings command", function()
  local test = require("tests.helpers")

  after_each(function()
    pcall(vim.api.nvim_del_user_command, "OrbitSettings")
  end)

  it(
    "creates the current settings file on demand and observes its saves",
    function()
      vim.g.orbitvim_settings_path = nil
      local settings = require("features.settings.config")
      local destination = settings.path()
      test.assert_path(vim.fn.stdpath("data") .. "/settings.json", destination)
      require("features.settings.runtime").setup()
      assert.is_nil(vim.uv.fs_stat(destination))
      require("features.settings.commands").setup()
      vim.cmd.OrbitSettings()
      assert.equals(destination, settings.path())
      test.assert_path(destination, vim.api.nvim_buf_get_name(0))
      local created =
        vim.json.decode(table.concat(vim.fn.readfile(destination), "\n"))
      assert.equals(
        vim.uri_from_fname(settings.schema_path),
        created["$schema"]
      )
      test.write_file(destination, '{"editor":{"shiftwidth":6}}')
      vim.api.nvim_exec_autocmds("BufWritePost", { pattern = destination })
      assert.equals(
        6,
        require("features.settings.runtime").info().values.editor.shiftwidth
      )
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
      require("features.settings.commands").setup()
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
        vim.uri_from_fname(require("features.settings.config").schema_path),
        decoded["$schema"]
      )
      test.write_file(vim.g.orbitvim_settings_path, "{broken")
      vim.cmd("edit!")
      require("features.settings.runtime").setup()
      assert.is_truthy(require("features.settings.runtime").info().error)
      vim.cmd.OrbitSettings()
      assert.equals("{broken", vim.api.nvim_get_current_line())
    end
  )
end)
