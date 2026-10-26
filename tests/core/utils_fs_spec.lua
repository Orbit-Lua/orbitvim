describe("utils.fs", function()
  local test = require("tests.helpers")
  local fs = require("utils.fs")

  it("scans files and directories with deterministic filtering", function()
    local root = test.temp_dir("scandir")
    vim.fn.mkdir(root .. "/subdir", "p")
    for _, name in ipairs({ "z.lua", "a.lua", "m.lua" }) do
      test.write_file(root .. "/" .. name, name)
    end

    assert.same({ "a.lua", "m.lua", "z.lua" }, fs.scandir(root, "file"))
    assert.same({ "subdir" }, fs.scandir(root, "directory"))
    assert.same(
      { "a.lua", "m.lua", "subdir", "z.lua" },
      fs.scandir(root, "all")
    )
    assert.same({}, fs.scandir(root .. "/missing", "all"))
  end)

  it(
    "deletes selected files while preserving skip-condition matches",
    function()
      local root = test.temp_dir("delete-files")
      test.write_file(root .. "/main.shada", "keep")
      test.write_file(root .. "/old.shada.tmp", "remove")

      fs.delete_files(root, {
        skip_condition = function(name)
          return name == "main.shada"
        end,
      })

      assert.equals(1, vim.fn.filereadable(root .. "/main.shada"))
      assert.equals(0, vim.fn.filereadable(root .. "/old.shada.tmp"))
    end
  )
end)
