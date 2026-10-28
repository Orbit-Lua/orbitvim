describe("buffer-dependent linter execution", function()
  it("builds one definition for preflight and native execution", function()
    local test = require("tests.helpers")
    test.configure_tool()
    vim.opt.runtimepath:append(test.plugin_path("nvim-lint"))
    local root = test.temp_dir("linter-execution")
    local script, marker = root .. "/probe.lua", root .. "/executed"
    test.write_file(
      script,
      "vim.fn.writefile({'executed'}, " .. vim.json.encode(marker) .. ")"
    )
    -- nvim-lint's Windows wrapper can split a spaced executable path when
    -- an argument also needs quoting (upstream issue #745). The shim keeps
    -- the linter command free of spaces on every platform.
    local windows = vim.fn.has("win32") == 1
    local shim = root .. "/probe" .. (windows and ".cmd" or "")
    local command = string.format(
      '"%s" --headless -u NONE -i NONE -l "%s"',
      vim.v.progpath,
      script
    )
    test.write_file(
      shim,
      windows and { "@" .. command } or { "#!/bin/sh", "exec " .. command }
    )
    if not windows then
      assert(vim.uv.fs_chmod(shim, 448))
    end
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
            cmd = shim,
            args = {},
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
