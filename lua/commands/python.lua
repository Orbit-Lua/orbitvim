local M = {}

function M.setup()
  vim.api.nvim_create_user_command("PyrightReCreateStub", function()
    local root = vim.fn.getcwd()
    local stubs = require("utils.fs").scandir(root .. "/typings", "directory")
    stubs = vim.tbl_filter(function(name)
      return not name:match("^%.orbitvim%-stub%-")
    end, stubs)
    vim.ui.select(stubs, { prompt = "Choose existing stub" }, function(name)
      if not name then
        return
      end
      require("runtime.python").recreate_stub(root, name, function(success, err)
        vim.notify(
          err or "Stub regenerated successfully",
          success and not err and vim.log.levels.INFO or vim.log.levels.WARN,
          { title = "Python" }
        )
      end)
    end)
  end, { desc = "Regenerate a Pyright stub with failure recovery" })
end

return M
