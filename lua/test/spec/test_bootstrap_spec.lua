describe("test bootstrap", function()
  it("redirects persistent state and logs below the test root", function()
    local root = vim.fs.normalize(vim.g.orbitvim_test_root)
    local paths = {
      tool_state = vim.fs.normalize(vim.g.tool_state_path),
      log = vim.fs.normalize(require("utils.logger").get_log_path()),
    }

    for name, path in pairs(paths) do
      assert.equals(
        root,
        path:sub(1, #root),
        name .. " must stay below the isolated test root"
      )
    end
  end)
end)
