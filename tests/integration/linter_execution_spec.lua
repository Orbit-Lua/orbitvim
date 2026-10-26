describe("buffer-dependent linter execution", function()
  it("builds one definition for preflight and native execution", function()
    local test = require("tests.helpers")
    vim.opt.runtimepath:append(test.plugin_path("nvim-lint"))
    local root = test.temp_dir("linter execution")
    local script, marker = root .. "/probe.lua", root .. "/executed"
    test.write_file(
      script,
      "vim.fn.writefile({'executed'}, " .. vim.json.encode(marker) .. ")"
    )
    local builds = 0
    local buffer = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buffer)
    vim.bo[buffer].filetype = "orbit_linter_fixture"
    require("runtime.linter").setup({
      events = { "BufWritePost" },
      linters_by_ft = { orbit_linter_fixture = { "probe" } },
      linters = {
        probe = function()
          builds = builds + 1
          return {
            cmd = vim.v.progpath,
            args = { "--headless", "-u", "NONE", "-i", "NONE", "-l", script },
            stdin = false,
            parser = function()
              return {}
            end,
          }
        end,
      },
    })
    vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buffer })
    assert.is_true(vim.wait(5000, function()
      return vim.uv.fs_stat(marker) ~= nil
    end, 10))
    assert.equals(1, builds)
  end)
end)
