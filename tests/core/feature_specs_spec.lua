describe("feature spec loading", function()
  local commands, original_require

  before_each(function()
    original_require = _G.require
    commands = vim.api.nvim_get_commands({ builtin = false })
  end)

  after_each(function()
    _G.require = original_require
    for name in pairs(vim.api.nvim_get_commands({ builtin = false })) do
      if not commands[name] then
        vim.api.nvim_del_user_command(name)
      end
    end
  end)

  it(
    "imports declarations without activation or editor registrations",
    function()
      local repository = vim.fn.getcwd()
      vim.opt.runtimepath = { repository, vim.env.VIMRUNTIME }
      vim.opt.packpath = {}
      for name in pairs(package.loaded) do
        if name:match("^features%.") then
          package.loaded[name] = nil
        end
      end

      local function registrations()
        local mappings = {}
        for _, mode in ipairs({ "n", "v", "x", "s", "o", "i", "l", "c", "t" }) do
          mappings[mode] = vim.api.nvim_get_keymap(mode)
        end
        return {
          commands = vim.api.nvim_get_commands({ builtin = false }),
          autocmds = vim.api.nvim_get_autocmds({}),
          mappings = mappings,
        }
      end

      local before = registrations()
      -- Observe require calls even when an activation module was already cached.
      _G.require = function(name)
        local owner = name:match("^features%.[^.]+%.([^.]+)")
        assert(
          owner ~= "runtime" and owner ~= "commands",
          "feature spec imported activation owner: " .. name
        )
        return original_require(name)
      end

      local imported = 0
      for name, kind in vim.fs.dir(repository .. "/lua/features") do
        local path = repository .. "/lua/features/" .. name .. "/spec.lua"
        if kind == "directory" and vim.fn.filereadable(path) == 1 then
          assert.is_table(require("features." .. name .. ".spec"))
          imported = imported + 1
        end
      end
      assert.is_true(imported > 0)
      vim.wait(10, function()
        return false
      end)
      assert.same(before, registrations())
    end
  )
end)
