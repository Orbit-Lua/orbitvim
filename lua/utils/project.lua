local M = {}

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
  local search_path = vim.fn.expand(startpath)
  if vim.fn.isdirectory(search_path) == 0 then
    search_path = vim.fn.fnamemodify(search_path, ":p:h")
  end
  search_path = vim.fn.escape(search_path, " ,;")
  for _, marker in ipairs(markers) do
    local found = vim.fn.finddir(marker, search_path .. ";")
    if type(found) == "string" and found ~= "" then
      return vim.fn.fnamemodify(found, ":p:h:h")
    end
    local found_file = vim.fn.findfile(marker, search_path .. ";")
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

local tool_configs = {
  eslint = {
    "eslint.config.js",
    "eslint.config.mjs",
    "eslint.config.cjs",
    "eslint.config.ts",
    "eslint.config.mts",
    "eslint.config.cts",
  },
  tailwindcss = {},
}
for _, extension in ipairs({ "js", "cjs", "mjs", "ts", "cts", "mts" }) do
  local name = "tailwind.config." .. extension
  table.insert(tool_configs.tailwindcss, name)
  table.insert(tool_configs.tailwindcss, "theme/static_src/" .. name)
end
local repository_markers = { ".git", ".hg", ".svn", ".bzr" }

local function file(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "file"
end

local function source_directory(filename)
  if type(filename) ~= "string" or filename == "" then
    return nil
  end
  local path = vim.fs.normalize(filename)
  if not (path:sub(1, 1) == "/" or path:match("^%a:/")) then
    return nil
  end
  return vim.fs.dirname(path)
end

local function declares_package(path, name)
  local handle = io.open(path, "r")
  if not handle then
    return false
  end
  local content = handle:read("*a")
  handle:close()
  local ok, manifest = pcall(vim.json.decode, content)
  if not ok or type(manifest) ~= "table" then
    return false
  end
  for _, section in ipairs({
    "dependencies",
    "devDependencies",
    "optionalDependencies",
    "peerDependencies",
  }) do
    local dependencies = manifest[section]
    if
      type(dependencies) == "table"
      and type(dependencies[name]) == "string"
      and dependencies[name] ~= ""
    then
      return true
    end
  end
  return false
end

local function tailwind_lock(path, kind)
  local handle = io.open(path, "r")
  if not handle then
    return false
  end
  local found = false
  for line in handle:lines() do
    if
      (kind == "mix" and line:match('^%s*"tailwind"%s*:'))
      or (
        kind == "gem"
        and (
          line:match("^%s+tailwindcss%-rails%s*%(")
          or line:match("^%s+tailwindcss%-ruby%s*%(")
        )
      )
    then
      found = true
      break
    end
  end
  handle:close()
  return found
end

---Return the nearest package/config directory when an ancestor proves eligibility.
---Within a repository, packages inherit workspace evidence, never sibling evidence.
---Without a repository, the nearest package/config is the search boundary.
---@param filename string absolute source filename
---@param tool "eslint"|"tailwindcss"
---@return string?
function M.tool_root(filename, tool)
  local directory = source_directory(filename)
  local configs = tool_configs[tool]
  if not directory or not configs then
    return nil
  end
  local boundary = vim.fs.root(directory, repository_markers)
  local nearest, eligible
  for ancestor in vim.fs.parents(directory .. "/_") do
    local manifest = ancestor .. "/package.json"
    local marked = file(manifest)
    local configured = false
    for _, config in ipairs(configs) do
      configured = configured or file(ancestor .. "/" .. config)
    end
    local lock = false
    if tool == "tailwindcss" then
      marked = marked
        or file(ancestor .. "/mix.lock")
        or file(ancestor .. "/Gemfile.lock")
      lock = tailwind_lock(ancestor .. "/mix.lock", "mix")
        or tailwind_lock(ancestor .. "/Gemfile.lock", "gem")
    end
    marked = marked or configured
    if marked and not nearest then
      nearest = ancestor
    end
    eligible = eligible
      or configured
      or lock
      or declares_package(manifest, tool)
    if ancestor == boundary or (not boundary and marked) then
      break
    end
  end
  return eligible and nearest or nil
end

---Resolve local or hoisted binaries without consulting the editor's cwd.
---@param filename string
---@param tool "eslint"|"tailwindcss"
---@param name string
---@return string
function M.tool_executable(filename, tool, name)
  local command = require("utils.os").is_win() and (name .. ".cmd") or name
  local root = M.tool_root(filename, tool)
  local directory = source_directory(filename)
  if not root or not directory then
    return command
  end
  local boundary = vim.fs.root(directory, repository_markers) or root
  for ancestor in vim.fs.parents(directory .. "/_") do
    local candidate = ancestor .. "/node_modules/.bin/" .. command
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
    if ancestor == boundary then
      break
    end
  end
  return command
end

return M
