describe("Python stub regeneration", function()
  local test = require("tests.helpers")
  local root, cwd, select, jobstart, notify, message

  before_each(function()
    cwd, select, jobstart, notify =
      vim.fn.getcwd(), vim.ui.select, vim.fn.jobstart, vim.notify
    root = test.temp_dir("project with spaces")
    message = nil
    test.write_file(root .. "/typings/pkg/old.pyi", "old stub")
    vim.api.nvim_set_current_dir(root)
    vim.notify = function(value)
      message = value
    end
    require("features.python.commands").setup()
  end)

  after_each(function()
    vim.api.nvim_set_current_dir(cwd)
    vim.ui.select, vim.fn.jobstart, vim.notify = select, jobstart, notify
    pcall(vim.api.nvim_del_user_command, "PyrightReCreateStub")
  end)

  it(
    "preserves existing stubs on spawn failure and captures the project before selection",
    function()
      local choose, received
      vim.ui.select = function(_, _, callback)
        choose = callback
      end
      vim.fn.jobstart = function(cmd, opts)
        received = opts.cwd
        assert.same({ "pyright", "--createstub", "pkg" }, cmd)
        return -1
      end
      vim.cmd.PyrightReCreateStub()
      vim.api.nvim_set_current_dir(test.temp_dir("other project"))
      choose("pkg")
      assert.is_not_nil(received, message)
      test.assert_path(root, received)
      assert.same(
        { "old stub" },
        vim.fn.readfile(root .. "/typings/pkg/old.pyi")
      )
    end
  )

  it(
    "restores the old stub after a failed process leaves partial output",
    function()
      vim.ui.select = function(_, _, callback)
        callback("pkg")
      end
      vim.fn.jobstart = function(_, opts)
        test.write_file(root .. "/typings/pkg/partial.pyi", "incomplete")
        opts.on_exit(1, 1)
        return 1
      end
      vim.cmd.PyrightReCreateStub()
      assert.is_true(vim.wait(1000, function()
        return message ~= nil
      end))
      assert.same(
        { "old stub" },
        vim.fn.readfile(root .. "/typings/pkg/old.pyi")
      )
      assert.equals(0, vim.fn.filereadable(root .. "/typings/pkg/partial.pyi"))
    end
  )

  it("replaces the old stub only after successful generation", function()
    vim.ui.select = function(_, _, callback)
      callback("pkg")
    end
    vim.fn.jobstart = function(_, opts)
      test.write_file(root .. "/typings/pkg/new.pyi", "generated")
      opts.on_exit(1, 0)
      return 1
    end
    vim.cmd.PyrightReCreateStub()
    assert.is_true(vim.wait(1000, function()
      return message ~= nil
    end))
    assert.same(
      { "generated" },
      vim.fn.readfile(root .. "/typings/pkg/new.pyi")
    )
    assert.equals(0, vim.fn.filereadable(root .. "/typings/pkg/old.pyi"))
    assert.same(
      {},
      vim.fn.glob(root .. "/typings/.orbitvim-stub-*", false, true)
    )
  end)
end)
