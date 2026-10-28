describe("test bootstrap", function()
  it("restores resources and module caches after a failed case", function()
    local helpers = require("tests.helpers")
    local original = package.loaded["orbitvim_test_probe"]
    local current = vim.api.nvim_get_current_buf()
    vim.keymap.set("n", "<F24>", "old", { buffer = current })
    local buffer, timer
    local ok = pcall(helpers.run_isolated, function()
      package.loaded["orbitvim_test_probe"] = {}
      vim.keymap.set("n", "<F24>", "changed", { buffer = current })
      vim.keymap.set("n", "<F23>", "leaked", { buffer = current })
      buffer = vim.api.nvim_create_buf(false, true)
      timer = vim.uv.new_timer()
      timer:start(10000, 0, function() end)
      error("deliberate test failure")
    end)
    assert.is_false(ok)
    assert.equals(original, package.loaded["orbitvim_test_probe"])
    assert.is_false(vim.api.nvim_buf_is_valid(buffer))
    assert.is_true(timer:is_closing())
    assert.equals("old", vim.fn.maparg("<F24>", "n", false, true).rhs)
    assert.equals("", vim.fn.maparg("<F23>", "n"))
    assert.has_error(function()
      helpers.write_file(
        vim.g.orbitvim_test_root .. "/../escape.txt",
        "refused"
      )
    end)
  end)
  it("redirects persistent state and logs below the test root", function()
    local root = vim.fs.normalize(vim.g.orbitvim_test_root)
    assert.equals(
      "NONE",
      vim.o.shadafile,
      "tests must not read or write user ShaDa"
    )
    local paths = {
      tool_state = vim.fs.normalize(vim.g.tool_state_path),
      settings = require("features.settings.config").path(),
      lsp_log = vim.fs.normalize(vim.lsp.log.get_filename()),
      log = vim.fs.normalize(require("utils.logger").get_log_path()),
    }

    for name, path in pairs(paths) do
      assert.equals(
        root .. "/",
        path:sub(1, #root + 1),
        name .. " must stay below the isolated test root"
      )
    end
  end)
end)
