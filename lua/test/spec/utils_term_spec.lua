describe("utils.term", function()
  local term = require("utils.term")

  describe("new", function()
    it("opens PowerShell without forwarding gsub replacement count", function()
      local original_display = term.display
      local original_has = vim.fn.has
      local original_jobstart = vim.fn.jobstart
      local original_shell = vim.o.shell
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

      term.display = original_display
      vim.fn.has = original_has
      vim.fn.jobstart = original_jobstart
      vim.o.shell = original_shell

      assert.is_true(ok, err)
      assert.same({ "pwsh.exe", "-NoLogo" }, captured_cmd)
    end)
  end)
end)
