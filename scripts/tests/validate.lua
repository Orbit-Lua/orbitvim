---@param root string
local function check(root)
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
      for _, skipped in ipairs({ "pending", "skip", "xit", "xdescribe" }) do
        assert(
          not source:match("%f[%a]" .. skipped .. "%s*%("),
          "skipped tests are not allowed: " .. path
        )
      end
      assert(
        not source:match("%.skip%s*%("),
        "skipped tests are not allowed: " .. path
      )
    end
  end

  assert(count > 0, "test suite contains no specs: " .. root)
end

assert(#arg > 0, "provide at least one test suite")
for _, root in ipairs(arg) do
  check(root)
end
