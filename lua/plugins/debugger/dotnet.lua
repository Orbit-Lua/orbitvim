-- NOTE: It also requires the correct .NET runtime based on the .NET version used in your project.
-- this dap config refer to:
-- https://codeberg.org/mfussenegter/nvim-dap/wiki/Debug-Adapter-installation#user-content-dotnet

local os_utils = require("utils.os")

local function pick_dll()
  return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
end

local function get_dotnet_project_name()
  local csproj_files = vim.fn.glob("*.csproj", false, true)

  if vim.tbl_isempty(csproj_files) then
    return ""
  end

  return vim.fn.getcwd()
    .. "/bin/Debug/"
    .. vim.fn.fnamemodify(csproj_files[1], ":t:r")
    .. ".dll"
end

local executable = "netcoredbg"

if os_utils.is_win() then
  executable = vim.fn.stdpath("data")
    .. "/mason/packages/netcoredbg/netcoredbg/"
    .. executable
    .. ".exe"
end

---@type Dap.Module
return {
  adapters = {
    coreclr = function(callback, config)
      if config.request == "attach" then
        callback({
          type = "executable",
          command = executable,
          args = { "--interpreter=vscode" },
        })
        return
      end

      vim.notify("Building project", vim.log.levels.INFO, { title = "Dotnet" })
      local dotnet_project = require("dotnet-cli").project
      local dotnet_cmd_build = require("dotnet-cli.commands.build")
      local build_cmd =
        dotnet_cmd_build.get_cmd(dotnet_project.get_csproj_files()[1], "Debug")

      vim.fn.jobstart(build_cmd, {
        -- refer to nvim doc: https://neovim.io/doc/user/job_control.html#on_exit
        -- job_id, exit_code, event_type
        on_exit = function(_, exit_code, _)
          if exit_code == 0 then
            vim.notify(
              "Build project successfully",
              vim.log.levels.INFO,
              { title = "Dotnet" }
            )

            callback({
              type = "executable",
              command = executable,
              args = { "--interpreter=vscode" },
            })
          else
            vim.notify(
              "Error occur when build project",
              vim.log.levels.ERROR,
              { title = "Dotnet" }
            )
          end
        end,
      })
    end,
  },

  configurations = {
    cs = {
      {
        type = "coreclr",
        name = "Launch .NET Core App (auto choose dll)",
        request = "launch",
        program = get_dotnet_project_name,
        cwd = vim.fn.getcwd(),
        justMyCode = false,
        stopAtEntry = false,
        env = {
          ASPNETCORE_ENVIRONMENT = "Development",
          ASPNETCORE_URLS = "http://localhost:7055;http://localhost:5056",
        },
      },

      {
        type = "coreclr",
        name = "Launch .NET Core App (choose dll)",
        request = "launch",
        program = pick_dll,
        cwd = vim.fn.getcwd(),
        justMyCode = false,
        stopAtEntry = false,
        env = {
          ASPNETCORE_ENVIRONMENT = "Development",
          ASPNETCORE_URLS = "http://localhost:7055;http://localhost:5056",
        },
      },

      {
        type = "coreclr",
        name = "Auto Attach to .NET Core Process",
        request = "attach",
        processId = function()
          local dotnet_job = require("dotnet-cli").job
          local dotnet_project = require("dotnet-cli").project
          local current_running_project =
            dotnet_project.get_current_running_project_name()

          if not current_running_project then
            vim.notify(
              "No running .NET Core process found",
              vim.log.levels.ERROR,
              { title = "Dotnet" }
            )
            return nil
          end

          local pid = dotnet_job.get_netcore_pid(current_running_project)

          vim.notify(
            "Attaching to process with PID: " .. pid,
            vim.log.levels.INFO,
            { title = "Dotnet" }
          )
          return pid
        end,
      },
    },
  },
}
