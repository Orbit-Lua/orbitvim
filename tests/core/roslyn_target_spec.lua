describe("Roslyn solution preference", function()
  local test = require("tests.helpers")
  local choose = require("config.lsp.roslyn").choose_target

  after_each(function()
    test.cleanup_all()
  end)

  it(
    "prefers the Git-root solution over a nested candidate without using cwd",
    function()
      local root = test.temp_dir("roslyn-root")
      test.write_file(root .. "/.git", "gitdir: elsewhere")
      test.write_file(root .. "/All.sln", "")
      test.write_file(root .. "/src/Part.sln", "")
      assert.equals(
        root .. "/All.sln",
        choose({
          root .. "/src/Part.sln",
          root .. "/All.sln",
        })
      )
    end
  )

  it(
    "does not choose between multiple root solutions even if one was filtered out",
    function()
      local root = test.temp_dir("roslyn-ambiguous")
      vim.fn.mkdir(root .. "/.git", "p")
      test.write_file(root .. "/All.sln", "")
      test.write_file(root .. "/Other.sln", "")
      assert.is_nil(choose({ root .. "/All.sln" }))
    end
  )

  it(
    "retains normal selection when the root solution is not a valid candidate",
    function()
      local root = test.temp_dir("roslyn-filtered")
      vim.fn.mkdir(root .. "/.git", "p")
      test.write_file(root .. "/All.sln", "")
      test.write_file(root .. "/src/Part.sln", "")
      assert.is_nil(choose({ root .. "/src/Part.sln" }))
      assert.is_nil(choose({}))
    end
  )
end)
