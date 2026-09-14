local M = {}

-- ---------------------------------------------------------------------------
-- FsPath – chainable path object
-- ---------------------------------------------------------------------------

---@class FsPath
---@field path string
local FsPath = {}
FsPath.__index = FsPath

---@param path string
---@return FsPath
function FsPath.new(path)
  return setmetatable({ path = path }, FsPath)
end

function FsPath:__tostring()
  return self.path
end

---Return a pretty, shortened version of the wrapped path.
---@param opts? {length?: integer, only_cwd?: boolean, transform_home?: boolean}
---@return string
function FsPath:pretty_path(opts)
  return M.pretty_path(self.path, opts)
end

---@return FsPath
function FsPath:get_cwd() -- luacheck: ignore
  return FsPath.new(M.get_cwd())
end

---Resolve the project root starting from the wrapped path.
---@return FsPath
function FsPath:get_root()
  return FsPath.new(M.get_root(self.path))
end

---Make the wrapped path relative to *root*.
---@param root string|FsPath
---@return string
function FsPath:make_relative(root)
  local root_str = type(root) == "table" and root.path or root
  return M.make_relative_path(self.path, root_str --[[@as string]])
end

---List directory entries.
---@param mode ScandirMode
---@return string[]
function FsPath:scandir(mode)
  return M.scandir(self.path, mode)
end

M.FsPath = FsPath

---Create a new FsPath for *path*, defaulting to the current buffer path.
---@param path? string
---@return FsPath
M.new = function(path)
  return FsPath.new(path or vim.fn.expand("%:p"))
end

-- ---------------------------------------------------------------------------
-- Utility functions (static, backward-compatible)
-- ---------------------------------------------------------------------------

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
    local cwd = M.get_cwd()

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

  -- local sep = package.config:sub(1, 1)
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

M.root_pattern = {
  ".git",
  ".hg",
  ".svn",
  ".bzr",
  "package.json",
  "pyproject.toml",
  "setup.py",
  "requirements.txt",
  "Pipfile",
  "Cargo.toml",
  "go.mod",
  "composer.json",
  "Gemfile",
  "Makefile",
  "CMakeLists.txt",
  "meson.build",
  "build.gradle",
  "build.gradle.kts",
  "pom.xml",
  ".idea",
  ".vscode",
}

---@param startpath string
---@param markers string[]
---@return string?
local function find_root_marker(startpath, markers)
  local Path = vim.fn.expand(startpath)
  for _, marker in ipairs(markers) do
    local found = vim.fn.finddir(marker, Path .. ";")
    if type(found) == "string" and found ~= "" then
      return vim.fn.fnamemodify(found, ":p:h:h")
    end
    local found_file = vim.fn.findfile(marker, Path .. ";")
    if type(found_file) == "string" and found_file ~= "" then
      return vim.fn.fnamemodify(found_file, ":p:h")
    end
  end
end

---@return string
M.get_cwd = function()
  return vim.fs.normalize(vim.fn.getcwd())
end

---Return the project root, optionally starting from *path*.
---When *path* is omitted the current buffer is used and LSP root-dir is
---consulted first (LSP is buffer-scoped, so it is skipped for explicit paths).
---@param path? string
---@return string
function M.get_root(path)
  local bufname = path or vim.api.nvim_buf_get_name(0)

  -- lsp root (only meaningful for the current buffer context)
  if not path then
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients > 0 then
      for _, client in ipairs(clients) do
        if client.config and client.config.root_dir then
          return client.config.root_dir
        end
      end
    end
  end

  -- marker files
  if bufname ~= "" then
    local root = find_root_marker(bufname, M.root_pattern)
    if root then
      return root
    end
  end

  -- current path of current file
  if bufname ~= "" then
    return vim.fn.fnamemodify(bufname, ":p:h")
  end

  -- fallback: cwd
  return M.get_cwd()
end

---@param buf_name string
---@param root string
---@return string
M.make_relative_path = function(buf_name, root)
  local normalized_buf = vim.fs.normalize(buf_name)
  local normalized_root = vim.fs.normalize(root)
  -- Ensure root ends with separator so the prefix check is exact.
  if normalized_root:sub(-1) ~= "/" then
    normalized_root = normalized_root .. "/"
  end
  if normalized_buf:sub(1, #normalized_root) == normalized_root then
    return normalized_buf:sub(#normalized_root + 1)
  end
  return ""
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

M.config_path = vim.fn.stdpath("config")
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
