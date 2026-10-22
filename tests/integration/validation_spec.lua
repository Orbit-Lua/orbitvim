describe("validation command", function()
  it(
    "returns failure through just when a suite introduces a skipped test",
    function()
      local test = require("tests.helpers")
      local root = test.temp_dir("validation command with spaces")
      for _, path in ipairs({ "justfile", "scripts/tests/validate.lua" }) do
        test.write_file(root .. "/" .. path, vim.fn.readfile(path))
      end
      for _, suite in ipairs({ "core", "integration" }) do
        test.write_file(
          root .. "/tests/" .. suite .. "/probe_spec.lua",
          'it("fixture", function() end)'
        )
      end
      local function validate()
        return vim
          .system({ "just", "validate-test-suites" }, { cwd = root, text = true })
          :wait(10000)
      end
      local accepted = validate()
      assert.equals(0, accepted.code, accepted.stderr)
      local skipped = "pending"
      test.write_file(
        root .. "/tests/core/probe_spec.lua",
        skipped .. '("fixture")'
      )
      local rejected = validate()
      assert.is_true(rejected.code ~= 0, rejected.stdout .. rejected.stderr)
      assert.is_truthy(
        rejected.stderr:find("skipped tests are not allowed", 1, true)
      )
    end
  )

  it("returns failure through just when startup raises an error", function()
    local test = require("tests.helpers")
    local root = test.temp_dir("startup command with spaces")
    for _, path in ipairs({ "justfile", "scripts/tests/smoke.lua" }) do
      test.write_file(root .. "/" .. path, vim.fn.readfile(path))
    end
    test.write_file(root .. "/init.lua", "return")
    local function smoke()
      return vim
        .system({ "just", "smoke" }, { cwd = root, text = true })
        :wait(10000)
    end
    local accepted = smoke()
    assert.equals(0, accepted.code, accepted.stderr)
    test.write_file(root .. "/init.lua", 'error("startup fixture failed")')
    local rejected = smoke()
    assert.is_true(rejected.code ~= 0, rejected.stdout .. rejected.stderr)
    assert.is_truthy(rejected.stderr:find("startup fixture failed", 1, true))
  end)
end)
