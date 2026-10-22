describe("first-start Lazy bootstrap", function()
  it(
    "loads the locked revision even when stable points to a newer commit",
    function()
      local test = require("tests.helpers")
      local root = test.temp_dir("bootstrap")
      local upstream = root .. "/upstream"
      local function git(...)
        local command = { "git", "-C", upstream }
        vim.list_extend(command, { ... })
        local result = vim.system(command, { text = true }):wait(10000)
        assert.equals(0, result.code, result.stderr)
        return vim.trim(result.stdout)
      end
      local function source(value)
        return 'return { setup = function() vim.fn.writefile({"'
          .. value
          .. '"}, vim.env.ORBITVIM_BOOTSTRAP_RESULT); vim.cmd("qall!") end }'
      end
      test.write_file(upstream .. "/lua/lazy/init.lua", source("locked"))
      git("init", "-b", "stable")
      git("add", ".")
      git(
        "-c",
        "user.name=OrbitVim",
        "-c",
        "user.email=tests@example.invalid",
        "commit",
        "-m",
        "test: create locked fixture"
      )
      local locked = git("rev-parse", "HEAD")
      test.write_file(upstream .. "/lua/lazy/init.lua", source("newer stable"))
      git("add", ".")
      git(
        "-c",
        "user.name=OrbitVim",
        "-c",
        "user.email=tests@example.invalid",
        "commit",
        "-m",
        "test: advance stable fixture"
      )
      test.write_file(
        root .. "/config/nvim/lazy-lock.json",
        vim.json.encode({ ["lazy.nvim"] = { branch = "main", commit = locked } })
      )
      test.write_file(root .. "/state/.keep", "")
      local environment = {
        XDG_CONFIG_HOME = root .. "/config",
        XDG_DATA_HOME = root .. "/data",
        XDG_STATE_HOME = root .. "/state",
        XDG_CACHE_HOME = root .. "/cache",
        NVIM_APPNAME = "nvim",
        NVIM_LOG_FILE = root .. "/nvim.log",
        ORBITVIM_BOOTSTRAP_RESULT = root .. "/loaded.txt",
        GIT_CONFIG_COUNT = "2",
        GIT_CONFIG_KEY_0 = "url."
          .. vim.uri_from_fname(upstream)
          .. ".insteadOf",
        GIT_CONFIG_VALUE_0 = "https://github.com/folke/lazy.nvim.git",
        GIT_CONFIG_KEY_1 = "protocol.file.allow",
        GIT_CONFIG_VALUE_1 = "always",
      }
      local result = vim
        .system({
          vim.v.progpath,
          "--headless",
          "--cmd",
          "set rtp^=" .. vim.fn.fnameescape(vim.fn.getcwd()),
          "-u",
          vim.fn.getcwd() .. "/init.lua",
          "+qall!",
        }, { env = environment, text = true })
        :wait(15000)
      assert.equals(0, result.code, result.stderr)
      assert.equals(
        1,
        vim.fn.filereadable(root .. "/loaded.txt"),
        result.stdout .. result.stderr
      )
      assert.same({ "locked" }, vim.fn.readfile(root .. "/loaded.txt"))
    end
  )
end)
