describe("utils.term", function()
  local term = require("utils.term")
  local originals
  local original_has

  before_each(function()
    originals = {
      display = term.display,
      has = vim.fn.has,
      jobstart = vim.fn.jobstart,
      shell = vim.o.shell,
      window = package.loaded["utils.window"],
      filetype = vim.bo.filetype,
    }
    original_has = vim.fn.has
  end)

  after_each(function()
    term.display = originals.display
    vim.fn.has = originals.has
    vim.fn.jobstart = originals.jobstart
    vim.o.shell = originals.shell
    vim.bo.filetype = originals.filetype
    package.loaded["utils.window"] = originals.window
  end)

  describe("new", function()
    it("opens PowerShell without forwarding gsub replacement count", function()
      local captured_cmd

      term.display = function() end
      vim.fn.has = function(name)
        if name == "win32" then
          return 1
        end
        return original_has(name)
      end
      vim.fn.jobstart = function(cmd)
        captured_cmd = cmd
        return 1
      end
      vim.o.shell = "pwsh.exe"

      local ok, err = pcall(function()
        term.new({ pos = "sp" })
      end)

      assert.is_true(ok, err)
      assert.same({ "pwsh.exe", "-NoLogo" }, captured_cmd)
    end)
  end)

  it("allows toggling from editor and managed terminal windows only", function()
    local floating = true
    package.loaded["utils.window"] = {
      is_floating = function()
        return floating
      end,
    }

    vim.bo.filetype = "lua"
    assert.is_false(term.can_toggle())
    floating = false
    assert.is_true(term.can_toggle())
    floating = true
    vim.bo.filetype = "Term_sp"
    assert.is_true(term.can_toggle())
  end)
end)
