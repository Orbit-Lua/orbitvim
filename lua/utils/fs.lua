local M = {}

local function is_within(path, root)
  path = vim.fs.normalize(path)
  root = vim.fs.normalize(root)
  return path == root or path:sub(1, #root + 1) == root .. "/"
end

---@param path? string
---@param opts? {length?: integer, only_cwd?: boolean, transform_home?: boolean}
---@return string
function M.pretty_path(path, opts)
  opts = opts or {}
  local length = opts.length or 3
  local full_path = path or vim.fn.expand("%:p")
  if full_path == "" then
    return ""
  end

  full_path = vim.fs.normalize(full_path)
  if opts.only_cwd then
    local cwd = M.get_cwd()
    if is_within(full_path, cwd) then
      full_path = full_path == cwd and "" or full_path:sub(#cwd + 2)
    end
  end

  if opts.transform_home then
    local home = vim.uv.os_homedir()
    if home then
      home = vim.fs.normalize(home)
      if is_within(full_path, home) then
        full_path = full_path == home and "~"
          or "~/" .. full_path:sub(#home + 2)
      end
    end
  end

  if full_path == "" then
    return ""
  end

  local parts = vim.split(full_path, "[\\/]", { plain = false })
  if #parts <= length or length == -1 then
    return table.concat(parts, "/")
  end

  local short_parts = { parts[1], "…" }
  vim.list_extend(
    short_parts,
    vim.list_slice(parts, #parts - length + 2, #parts)
  )
  return table.concat(short_parts, "/")
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

local function find_root_marker(startpath, markers)
  local path = vim.fn.expand(startpath)
  for _, marker in ipairs(markers) do
    local found = vim.fn.finddir(marker, path .. ";")
    if type(found) == "string" and found ~= "" then
      return vim.fn.fnamemodify(found, ":p:h:h")
    end
    local found_file = vim.fn.findfile(marker, path .. ";")
    if type(found_file) == "string" and found_file ~= "" then
      return vim.fn.fnamemodify(found_file, ":p:h")
    end
  end
end

function M.get_cwd()
  return vim.fs.normalize(vim.fn.getcwd())
end

---@param path? string
---@return string
function M.get_root(path)
  local bufname = path or vim.api.nvim_buf_get_name(0)

  if not path then
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      if client.config and client.config.root_dir then
        return client.config.root_dir
      end
    end
  end

  if bufname ~= "" then
    local root = find_root_marker(bufname, M.root_pattern)
    if root then
      return root
    end
    return vim.fn.fnamemodify(bufname, ":p:h")
  end

  return M.get_cwd()
end

function M.make_relative_path(buf_name, root)
  local path = vim.fs.normalize(buf_name)
  local normalized_root = vim.fs.normalize(root)
  if path == normalized_root then
    return ""
  end
  if not is_within(path, normalized_root) then
    return ""
  end
  return path:sub(#normalized_root + 2)
end

---@alias ScandirMode "file" | "directory" | "all"
---@param path string
---@param mode ScandirMode
---@return string[]
function M.scandir(path, mode)
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
    if mode == "all" or entry_type == mode then
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
  ms_build = M.config_path .. "/lua/config/lsp/schema/Microsoft.Build.xsd",
}

---@class DeleteFilesOpts
---@field success_message? string
---@field skip_condition? fun(file_name: string, file_path: string): boolean

function M.delete_files(path, opts)
  opts = opts or {}
  local files = vim.fn.isdirectory(path) == 1
      and vim.fn.glob(path .. "/*", false, true)
    or { path }
  local error_count = 0

  for _, file in ipairs(files) do
    local file_name = vim.fn.fnamemodify(file, ":t")
    if not (opts.skip_condition and opts.skip_condition(file_name, file)) then
      local result = vim.fn.delete(file)
      error_count = error_count + result
      if result ~= 0 then
        vim.notify(
          "Couldn't delete file '" .. file_name .. "'",
          vim.log.levels.WARN
        )
      end
    end
  end

  if error_count == 0 then
    vim.notify(
      opts.success_message or "Successfully deleted all files",
      vim.log.levels.INFO
    )
  end
end

return M
