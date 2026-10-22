describe("settings command", function()
  local test = require("tests.helpers")

  after_each(function()
    pcall(vim.api.nvim_del_user_command, "OrbitSettings")
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
