local M = {}

function M.build_preview(plugin)
  local info = vim.json.decode(
    table.concat(vim.fn.readfile(plugin.dir .. "/package.json"), "\n")
  )
  local os_utils = require("utils.os")
  local windows = os_utils.is_win()
  local platform = windows and "win" or "linux"
  if os_utils.is_mac() then
    platform = vim.uv.os_uname().machine == "arm64" and "macos-arm64" or "macos"
  end
  local executable = plugin.dir
    .. "/app/bin/markdown-preview-"
    .. platform
    .. (windows and ".exe" or "")
  local function installed()
    if not vim.uv.fs_stat(executable) then
      return false
    end
    local result = vim
      .system({ executable, "--version" }, { text = true })
      :wait(10000)
    return result.code == 0 and vim.trim(result.stdout or "") == info.version
  end
  if installed() then
    return
  end
  local command = windows
      and { "cmd.exe", "/d", "/c", "install.cmd", "v" .. info.version }
    or { "bash", "./install.sh", "v" .. info.version }
  local result = vim
    .system(command, { cwd = plugin.dir .. "/app", text = true })
    :wait(120000)
  if result.code ~= 0 then
    error(
      "Markdown preview installation failed:\n"
        .. (result.stderr or "")
        .. (result.stdout or ""),
      0
    )
  end
  assert(
    installed(),
    "Markdown preview installer did not produce the expected executable version"
  )
end

return M
