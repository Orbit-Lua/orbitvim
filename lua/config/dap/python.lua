local py_cmd = require("cmds.python")
local os_utils = require("utils.os")

local is_debugpy_installed = function()
  local venv_path = py_cmd.get_venv_path()

  if os_utils.is_win() then
    venv_path = venv_path .. "/Scripts/debugpy.exe"
  else
    venv_path = venv_path .. "/bin/debugpy"
  end

  return vim.fn.filereadable(venv_path) == 1
end

---@type Dap.Module
return {
  adapters = {
    python = function(callback, config)
      if config.request == "launch" then
        if py_cmd.check_venv() ~= 0 then
          return
        end

        if not is_debugpy_installed() then
          vim.notify(
            "debugpy not found in venv, please install debugpy in venv",
            vim.log.levels.WARN
          )
          return
        end

        callback({
          type = "executable",
          command = py_cmd.get_virtual_python_path(),
          args = { "-m", "debugpy.adapter" },
          options = {
            source_filetype = "python",
          },
        })
      else
        local host = (config.connect or config).host or "127.0.0.1"
        local port = (config.connect or config).port or "8001"

        callback({
          type = "server",
          host = host,
          port = assert(
            port,
            "`connect.port` is required for a python `attach` configuration"
          ),
          options = {
            source_filetype = "python",
          },
        })
      end
    end,
  },

  -- Options below are for debugpy
  -- see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options
  configurations = {
    python = {
      {
        type = "python",
        request = "launch",
        name = "launch debugpy server",
        program = "${file}",
      },

      {
        type = "python",
        request = "attach",
        name = "attach to active debugpy server",
        connect = {
          host = "127.0.0.1",
          port = "8001",
        },
      },
    },
  },
}
