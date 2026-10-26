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

return M
