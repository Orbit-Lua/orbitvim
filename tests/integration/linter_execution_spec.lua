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
    require("features.linter.runtime").setup({
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
  it(
    "scopes ESLint execution and formatter selection to each source project",
    function()
      local test = require("tests.helpers")
      test.configure_tool()
      assert.equals(
        1,
        vim.fn.executable("node"),
        "Node.js is required for adapter fixtures"
      )
      vim.opt.runtimepath:append(test.plugin_path("nvim-lint"))
      vim.opt.runtimepath:append(test.plugin_path("conform.nvim"))
      local root = test.temp_dir("eslint-projects")
      local a, b = root .. "/a", root .. "/b"
      local windows = vim.fn.has("win32") == 1
      local function executable(directory)
        local script = directory .. "/probe.js"
        test.write_file(script, [[
const fs = require('node:fs');
process.stdin.resume();
process.stdin.on('end', () => {
]] .. "fs.writeFileSync(" .. vim.json.encode(
          directory .. "/executed.json"
        ) .. ", JSON.stringify({cwd:process.cwd()}));\n" .. [[
process.stdout.write(JSON.stringify([{
  filePath:process.argv[process.argv.length-1],
  messages:[{ruleId:'probe',severity:2,message:'fixture diagnostic',line:1,column:1}]
}]));
});
]])
        local path = directory
          .. "/node_modules/.bin/eslint_d"
          .. (windows and ".cmd" or "")
        test.write_file(
          path,
          windows and ('@node "' .. script .. '" %*')
            or ('#!/bin/sh\nexec node "' .. script .. '" "$@"\n')
        )
        if not windows then
          assert(vim.uv.fs_chmod(path, 448))
        end
        vim.fn.mkdir(directory .. "/.git", "p")
        return path
      end
      local command = executable(a)
      executable(b)
      test.write_file(
        a .. "/package.json",
        '{"devDependencies":{"eslint":"1"}}'
      )
      test.write_file(b .. "/package.json", "{}")
      local first, second =
        vim.api.nvim_create_buf(true, false),
        vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(first, a .. "/src/file with spaces.js")
      vim.api.nvim_buf_set_name(second, b .. "/src/file.js")
      vim.bo[first].filetype, vim.bo[second].filetype =
        "javascript", "javascript"
      local previous_cwd = vim.fn.getcwd()
      local ok, err = pcall(function()
        vim.api.nvim_set_current_dir(b)
        local lint = require("lint")
        local opts = vim.deepcopy(require("features.linter.config"))
        opts.events = { "BufWritePost" }
        require("features.linter.runtime").setup(opts)
        local namespace = lint.get_namespace("eslint_d")
        vim.api.nvim_exec_autocmds("BufWritePost", { buffer = first })
        vim.api.nvim_set_current_buf(second)
        assert.is_true(vim.wait(5000, function()
          return #vim.diagnostic.get(first, { namespace = namespace }) > 0
        end, 10))
        local execution = vim.json.decode(
          table.concat(vim.fn.readfile(a .. "/executed.json"), "\n")
        )
        test.assert_path(a, execution.cwd)
        local conform = require("conform")
        local formatter =
          vim.deepcopy(require("features.formatter.config").formatters.eslint_d)
        conform.setup({
          formatters = { eslint_d = formatter },
          formatters_by_ft = { javascript = { "eslint_d" } },
        })
        local active = conform.get_formatter_info("eslint_d", first)
        assert.is_true(active.available)
        test.assert_path(command, active.command)
        -- A real available command isolates the project condition from availability.
        conform.formatters.eslint_d.command = vim.v.progpath
        assert.is_false(
          conform.get_formatter_info("eslint_d", second).available
        )
        conform.formatters.eslint_d.command = root .. "/missing-eslint"
        assert.is_false(
          conform.get_formatter_info("eslint_d", second).available
        )
        vim.api.nvim_exec_autocmds("BufWritePost", { buffer = second })
        local elapsed = false
        vim.defer_fn(function()
          elapsed = true
        end, 350)
        assert.is_true(vim.wait(1000, function()
          return elapsed
        end, 10))
        assert.is_nil(vim.uv.fs_stat(b .. "/executed.json"))
        assert.same(
          {},
          require("utils.logger").get_entries("linter", "eslint_d")
        )
        test.write_file(b .. "/package.json", '{"dependencies":{"eslint":"1"}}')
        vim.api.nvim_exec_autocmds("BufWritePost", { buffer = second })
        vim.api.nvim_set_current_buf(first)
        assert.is_true(vim.wait(5000, function()
          return #vim.diagnostic.get(second, { namespace = namespace }) > 0
        end, 10))
        execution = vim.json.decode(
          table.concat(vim.fn.readfile(b .. "/executed.json"), "\n")
        )
        test.assert_path(b, execution.cwd)
      end)
      vim.api.nvim_set_current_dir(previous_cwd)
      assert(ok, err)
    end
  )
end)
