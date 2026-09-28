local M = {}

local fs = require("utils.fs")
local python = require("runtime.python")

M.title = "Python"

M.get_venv_path = python.get_venv_path
M.get_virtual_python_path = python.get_virtual_python_path
M.check_venv = python.check_venv

M.get_pyright_create_stub_cmd = function()
  return { "pyright", "--createstub" }
end

local pyright_create_stub = function(cmd)
  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify(
          "Create stub successfully",
          vim.log.levels.INFO,
          { title = M.title }
        )
      else
        vim.notify(
          "Error occor when create stub",
          vim.log.levels.ERROR,
          { title = M.title }
        )
      end
    end,
  })
end

function M.setup()
  vim.api.nvim_create_user_command("PyrightReCreateStub", function()
    local typing_path = vim.fn.getcwd() .. "/typings"
    local exist_stubs = fs.scandir(typing_path, "directory")
    local cmd = M.get_pyright_create_stub_cmd()

    vim.ui.select(
      exist_stubs,
      { prompt = "Choose exist stub" },
      function(item, _index)
        if item == nil then
          return
        end

        local success = vim.fn.delete(typing_path .. "/" .. item, "rf")
        if success == 0 then
          table.insert(cmd, item)
          pyright_create_stub(cmd)
        else
          vim.notify(
            "Error occor when delete existing stub",
            vim.log.levels.ERROR,
            { title = M.title }
          )
        end
      end
    )
  end, { desc = "pyright re-generate stub (delete old)" })
end

return M
