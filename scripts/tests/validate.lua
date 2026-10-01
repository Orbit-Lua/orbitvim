local M = {}

---@param root string
function M.check(root)
  local handle = assert(vim.uv.fs_scandir(root), "missing test suite: " .. root)
  local count = 0

  while true do
    local name, entry_type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end

    if entry_type == "file" and name:match("_spec%.lua$") then
      count = count + 1
      local path = root .. "/" .. name
      local lines = vim.fn.readfile(path)
      local source = table.concat(lines, "\n")
      local has_pending = source:match("%f[%a]pending%s*%(") ~= nil
      assert(not has_pending, "pending tests are not allowed: " .. path)
    end
  end

  assert(count > 0, "test suite contains no specs: " .. root)
end

return M
