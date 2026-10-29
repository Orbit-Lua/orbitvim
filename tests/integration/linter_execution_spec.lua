describe("buffer-dependent linter execution", function()
  it(
    "preserves spaced commands and arguments through native execution",
    function()
      local test = require("tests.helpers")
      test.configure_tool()
      vim.opt.runtimepath:append(test.plugin_path("nvim-lint"))
      local windows = vim.fn.has("win32") == 1
      local root = test.temp_dir("linter execution with spaces")
      local command = root .. "/node" .. (windows and ".exe" or "")
      local node = vim.fn.exepath(windows and "node.exe" or "node")
      assert.is_not.equals("", node, "Node.js is required for adapter fixtures")
      assert(vim.uv.fs_copyfile(node, command))
      if not windows then
        assert(vim.uv.fs_chmod(command, 448))
      end
      local script = root .. "/probe with spaces.js"
      test.write_file(
        script,
        [[
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  process.stdout.write(JSON.stringify({
    input, args: process.argv.slice(2), cwd: process.cwd(),
    env: process.env.ORBIT_LINT_PROBE,
  }));
});
]]
      )
      local shim = root .. "/shim with spaces" .. (windows and ".cmd" or "")
      local invocation = '"' .. command .. '" "' .. script .. '"'
      test.write_file(
        shim,
        windows and ("@" .. invocation .. " %*")
          or ("#!/bin/sh\nexec " .. invocation .. ' "$@"\n')
      )
      if not windows then
        assert(vim.uv.fs_chmod(shim, 448))
      end
      local lint = require("lint")
      local builds = 0
      for _, adapter in ipairs({ "native", "shim" }) do
        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buffer)
        vim.bo[buffer].filetype = "orbit_linter_fixture"
        vim.api.nvim_buf_set_lines(
          buffer,
          0,
          -1,
          false,
          { adapter, "second line" }
        )
        local name = "orbit_execution_" .. adapter
        local namespace = lint.get_namespace(name)
        require("features.linter.runtime").setup({
          events = { "BufWritePost" },
          linters_by_ft = { orbit_linter_fixture = { name } },
          linters = {
            [name] = function()
              builds = builds + 1
              return {
                cmd = function()
                  return adapter == "native" and command or shim
                end,
                args = adapter == "native"
                    and { script, "argument with spaces" }
                  or { "argument with spaces" },
                append_fname = false,
                stdin = true,
                cwd = root,
                env = { ORBIT_LINT_PROBE = "preserved" },
                parser = function(output)
                  return { { lnum = 0, col = 0, message = output } }
                end,
              }
            end,
          },
        })
        vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buffer })
        assert.is_true(vim.wait(5000, function()
          return #vim.diagnostic.get(buffer, { namespace = namespace }) == 1
            and #lint.get_running(buffer) == 0
        end, 10))
        local diagnostics =
          vim.diagnostic.get(buffer, { namespace = namespace })
        local result = vim.json.decode(diagnostics[1].message)
        assert.same({ "argument with spaces" }, result.args)
        assert.equals(adapter .. "\nsecond line\n", result.input)
        test.assert_path(root, result.cwd)
        assert.equals("preserved", result.env)
        assert.same({}, require("utils.logger").get_entries("linter", name))
      end
      assert.equals(2, builds)
    end
  )
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
