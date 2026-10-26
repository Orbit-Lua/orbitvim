local M = {}

---Write a complete file beside its destination, then atomically replace it.
---@param path string
---@param contents string
---@param opts? { exclusive?: boolean }
---@return boolean, string?, string?
function M.atomic_write(path, contents, opts)
  local parent = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(parent) == 0 then
    local mkdir_ok, created = pcall(vim.fn.mkdir, parent, "p")
    if not mkdir_ok then
      return false, tostring(created)
    end
    if created == 0 and vim.fn.isdirectory(parent) == 0 then
      return false, "failed to create parent directory: " .. parent
    end
  end

  local file, temporary, open_code =
    vim.uv.fs_mkstemp(path .. ".orbitvim-XXXXXX")
  if not file then
    return false, temporary, open_code
  end
  local offset, write_error = 0, nil
  while offset < #contents do
    local written, err = vim.uv.fs_write(file, contents:sub(offset + 1), offset)
    if not written or written == 0 then
      write_error = err or "temporary write made no progress"
      break
    end
    offset = offset + written
  end
  local closed, close_error = vim.uv.fs_close(file)
  if write_error or not closed then
    vim.uv.fs_unlink(temporary)
    return false, write_error or close_error
  end

  local publish = opts and opts.exclusive and vim.uv.fs_link or vim.uv.fs_rename
  local rename_ok, rename_error, code = publish(temporary, path)
  if not rename_ok or (opts and opts.exclusive) then
    local cleaned, cleanup_error = vim.uv.fs_unlink(temporary)
    if not cleaned then
      return false, "temporary cleanup failed: " .. tostring(cleanup_error)
    end
  end
  if not rename_ok then
    return false, rename_error, code
  end
  return true
end

---@param path? string
---@param opts? {length?: integer, only_cwd?: boolean, transform_home?: boolean}
---@return string
M.pretty_path = function(path, opts)
  opts = opts or {}

  local length = opts.length or 3
  local full_path = path or vim.fn.expand("%:p")

  if full_path == "" then
    return ""
  end

  -- Normalize and get cwd
  full_path = vim.fs.normalize(full_path)

  if opts.only_cwd then
    local cwd = require("utils.project").get_cwd()

    -- remove cwd prefix
    if full_path:find(cwd, 1, true) == 1 then
      full_path = full_path:sub(#cwd + 2) -- +2 to remove slash
    end
  end

  if opts.transform_home then
    local home = vim.uv.os_homedir()
    if home and full_path:find(home, 1, true) == 1 then
      full_path = "~" .. full_path:sub(#home + 1)
    end
  end

  local sep = "/"
  local parts = vim.split(full_path, "[\\/]", { plain = false })

  if #parts <= length or length == -1 then
    return table.concat(parts, sep)
  end

  local short_parts = { parts[1], "…" }
  vim.list_extend(
    short_parts,
    vim.list_slice(parts, #parts - length + 2, #parts)
  )

  return table.concat(short_parts, sep)
end

---@param buf_name string
---@param root string
---@return string
M.plenary_make_relative_path = function(buf_name, root)
  local ok, Path = pcall(require, "plenary.path")
  if ok then
    return Path:new(buf_name):make_relative(root)
  end

  return ""
end

---@alias ScandirMode "file" | "directory" | "all"

---@param path string
---@param mode ScandirMode
---@return table
M.scandir = function(path, mode)
  local names = {}
  local dir_handle = vim.uv.fs_scandir(path)
  if not dir_handle then
    return names
  end

  while true do
    local name, entry_type = vim.uv.fs_scandir_next(dir_handle)
    if not name then
      break
    end
    if (mode == "all") or (entry_type == mode) then
      table.insert(names, name)
    end
  end

  table.sort(names)
  return names
end

M.config_path = vim.fs.dirname(
  assert(
    vim.api.nvim_get_runtime_file("settings.schema.json", false)[1],
    "OrbitVim source root is missing"
  )
)
M.data_path = vim.fn.stdpath("data")
M.mason_pkg_path = vim.fn.stdpath("data") .. "/mason/packages"

M.schema_paths = {
  -- msbuild schema ref:
  -- https://learn.microsoft.com/en-us/visualstudio/msbuild/msbuild-project-file-schema-reference?view=visualstudio
  ms_build = M.config_path .. "/lua/config/lsp/schema/Microsoft.Build.xsd",
}

---@class DeleteFilesOpts
---@field success_message? string
---@field skip_condition? fun(file_name: string, file_path: string): boolean

---@param path string
---@param opts? DeleteFilesOpts
M.delete_files = function(path, opts)
  opts = opts or {}
  local files
  if vim.fn.isdirectory(path) == 1 then
    files = vim.fn.glob(path .. "/*", false, true)
  else
    files = { path }
  end

  local error_count = 0
  for _, file in ipairs(files) do
    local file_name = vim.fn.fnamemodify(file, ":t")
    if opts.skip_condition and opts.skip_condition(file_name, file) then
      goto continue
    end

    local result = vim.fn.delete(file)
    error_count = error_count + result

    if result ~= 0 then
      vim.notify(
        "Couldn't delete file '" .. file_name .. "'",
        vim.log.levels.WARN
      )
    end
    ::continue::
  end

  if error_count == 0 then
    vim.notify(
      opts.success_message or "Successfully deleted all files",
      vim.log.levels.INFO
    )
  end
end

return M
