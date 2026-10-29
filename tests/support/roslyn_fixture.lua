local M = {}

---Supply inert executable prerequisites without requiring a .NET installation.
function M.path(directory, previous)
  local windows = vim.fn.has("win32") == 1
  vim.fn.mkdir(directory, "p")
  for _, executable in ipairs({ "dotnet", "roslyn-language-server" }) do
    local path = directory .. "/" .. executable .. (windows and ".cmd" or "")
    assert(
      vim.fn.writefile(
        windows and { "@exit /b 0" } or { "#!/bin/sh", "exit 0" },
        path
      ) == 0
    )
    if not windows then
      assert(vim.uv.fs_chmod(path, 448))
    end
  end
  return directory .. (windows and ";" or ":") .. previous
end

return M
