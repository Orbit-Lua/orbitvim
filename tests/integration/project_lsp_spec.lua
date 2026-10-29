describe("Tailwind project activation", function()
  it(
    "gates the installed upstream root resolver without changing its result",
    function()
      local test = require("tests.helpers")
      local plugin = test.plugin_path("nvim-lspconfig")
      assert.equals(1, vim.fn.isdirectory(plugin), "nvim-lspconfig is required")
      vim.opt.runtimepath:append(plugin)
      test.configure_tool()
      -- Register the real configuration without starting an external server.
      assert.is_true(
        require("hangar.state").set_enabled("lsp", "tailwindcss", false)
      )
      package.loaded["features.theme.runtime"] = { load_cache = function() end }
      package.loaded["features.hangar.config.packages"] =
        { lsp_servers = { "tailwindcss" } }
      local original = vim.lsp.config
      local ok, err = pcall(function()
        vim.lsp.config = vim.deepcopy(original)
        local upstream = vim.lsp.config.tailwindcss.root_dir
        assert.is_function(upstream)
        local root = test.temp_dir("tailwind upstream with spaces")
        local a, b = root .. "/tailwind", root .. "/plain"
        vim.fn.mkdir(a .. "/.git", "p")
        vim.fn.mkdir(b .. "/.git", "p")
        test.write_file(
          a .. "/package.json",
          '{"devDependencies":{"tailwindcss":"4"}}'
        )
        local first, second =
          vim.api.nvim_create_buf(true, false),
          vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(first, a .. "/view.html")
        vim.api.nvim_buf_set_name(second, b .. "/view.html")
        local expected
        upstream(first, function(value)
          expected = value
        end)
        assert.is_not_nil(expected)
        require("features.lsp.runtime").register_servers({
          servers = {
            tailwindcss = require("features.lsp.config.servers.typescript").servers.tailwindcss,
          },
          setup = {},
          disable_default_settings = {},
        })
        local resolved
        vim.lsp.config.tailwindcss.root_dir(first, function(value)
          resolved = value
        end)
        test.assert_path(expected, resolved)
        vim.lsp.config.tailwindcss.root_dir(second, function()
          error("unrelated repository activated")
        end)
        assert.is_false(
          require("hangar.state").is_enabled("lsp", "tailwindcss")
        )
      end)
      vim.lsp.config = original
      assert(ok, err)
    end
  )
end)
