local python = require("runtime.python")

---@type Dap.Module
return {
  adapters = {
    python = function(callback, config)
      if config.request == "launch" then
        local debugpy = python.venv_executable("debugpy")
        if not debugpy then
          vim.notify("Activate a virtual environment", vim.log.levels.WARN)
          return
        end
        if vim.fn.filereadable(debugpy) ~= 1 then
          vim.notify(
            "Install debugpy in the virtual environment",
            vim.log.levels.WARN
          )
          return
        end

        callback({
          type = "executable",
          command = python.venv_python(),
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
