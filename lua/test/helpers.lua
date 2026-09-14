local M = {}

local cleanup_paths = {}

local function test_root()
  local root = vim.g.orbitvim_test_root
  assert(type(root) == "string" and root ~= "", "test bootstrap is not loaded")
  return root
end

---@param name string
---@return string
function M.plugin_path(name)
  local data_path = vim.g.orbitvim_test_plugin_data_path
  assert(
    type(data_path) == "string" and data_path ~= "",
    "test plugin data path is unavailable"
  )
  return data_path .. "/lazy/" .. name
end

---@param suffix? string
---@return string
function M.temp_dir(suffix)
  local path = test_root()
    .. "/tmp/"
    .. (suffix or tostring(#cleanup_paths + 1))
  assert(vim.fn.mkdir(path, "p") == 1 or vim.fn.isdirectory(path) == 1)
  table.insert(cleanup_paths, path)
  return path
end

---@param path string
---@param content string|string[]
function M.write_file(path, content)
  local parent = vim.fn.fnamemodify(path, ":h")
  assert(vim.fn.mkdir(parent, "p") == 1 or vim.fn.isdirectory(parent) == 1)
  local lines = type(content) == "table" and content or { content }
  assert.equals(0, vim.fn.writefile(lines, path))
end

function M.cleanup_all()
  for _, path in ipairs(cleanup_paths) do
    if vim.fn.isdirectory(path) == 1 or vim.fn.filereadable(path) == 1 then
      vim.fn.delete(path, "rf")
    end
  end
  cleanup_paths = {}
end

return M
