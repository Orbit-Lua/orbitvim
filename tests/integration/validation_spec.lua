describe("validation commands", function()
  local test = require("tests.helpers")

  local function fixture(paths)
    local root = test.temp_dir("validation with spaces")
    for _, path in ipairs(paths) do
      test.write_file(root .. "/" .. path, vim.fn.readfile(path))
    end
    return root
  end

  local function run(root, recipe)
    return vim
      .system({ "just", recipe }, {
        cwd = root,
        text = true,
        env = {
          ORBITVIM_TEST_PLUGIN_DATA = vim.g.orbitvim_test_plugin_data_path,
        },
      })
      :wait(45000)
  end

  it(
    "rejects skipped, empty and uncompleted execution through the suite recipe",
    function()
      local root = fixture({
        "justfile",
        "tests/support/run_suite.lua",
        "tests/support/run_spec.lua",
        "tests/support/validate.lua",
        "tests/support/minimal.vim",
        "tests/helpers.lua",
      })
      local path = root .. "/tests/core/probe_spec.lua"
      test.write_file(
        path,
        'describe("fixture", function() it("runs", function() end) end)'
      )
      local accepted = run(root, "test-core")
      assert.equals(0, accepted.code, accepted.stdout .. accepted.stderr)
      for _, source in ipairs({
        'describe("fixture", function() local ignore=pending; ignore("skipped") end)',
        'describe("fixture", function() end)',
        "return",
        'describe("fixture", function() it("fails", function() error("failure") end) end)',
        [[describe("fixture", function()
  it("emits an uncaught runtime error", function()
    vim.api.nvim_echo({{"runtime fixture error"}}, true, {err=true})
  end)
end)]],
      }) do
        test.write_file(path, source)
        local rejected = run(root, "test-core")
        assert.is_true(rejected.code ~= 0, rejected.stdout .. rejected.stderr)
      end
    end
  )

  it(
    "rejects synchronous and scheduled startup errors after UI attachment",
    function()
      local root = fixture({
        "justfile",
        "tests/support/smoke.lua",
        "tests/support/session.lua",
        "tests/support/roslyn_fixture.lua",
      })
      test.write_file(
        root .. "/lua/features/hangar/config.lua",
        "return {lsp={},dap={},formatter={},linter={}}"
      )
      test.write_file(root .. "/lua/core/lazy.lua", "return {}")
      test.write_file(
        root .. "/init.lua",
        [[
package.loaded.roslyn = {}
package.loaded['roslyn.config'] = {}
vim.lsp.config('roslyn', { on_init = { function() end }, on_attach = function() end })
]]
      )
      local accepted = run(root, "smoke")
      assert.equals(0, accepted.code, accepted.stdout .. accepted.stderr)
      for _, source in ipairs({
        'error("startup fixture failed")',
        'vim.schedule(function() error("delayed fixture failed") end)',
      }) do
        test.write_file(root .. "/init.lua", source)
        local rejected = run(root, "smoke")
        assert.is_true(rejected.code ~= 0, rejected.stdout .. rejected.stderr)
        assert.is_truthy(
          (rejected.stdout .. rejected.stderr):find("fixture failed", 1, true)
        )
      end
    end
  )
end)
