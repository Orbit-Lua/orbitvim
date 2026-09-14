describe("utils.cmp", function()
  local cmp_utils = require("utils.cmp")

  describe("snippet_replace", function()
    it("transforms every placeholder with its number and text", function()
      local seen = {}
      local result = cmp_utils.snippet_replace("${3:a} ${7:b}", function(p)
        table.insert(seen, { tonumber(p.n), p.text })
        return p.n .. ":" .. p.text .. "!"
      end)

      assert.equals("3:a! 7:b!", result)
      assert.same({ { 3, "a" }, { 7, "b" } }, seen)
    end)

    it("preserves text without matching placeholders", function()
      for _, input in ipairs({ "plain text", "$0 end", "${broken}" }) do
        assert.equals(
          input,
          cmp_utils.snippet_replace(input, function(p)
            return p.text
          end)
        )
      end
    end)
  end)

  describe("map", function()
    it(
      "uses value, function, and nil fallbacks when no action handles input",
      function()
        assert.equals("fallback", cmp_utils.map({}, "fallback")())
        assert.equals(
          "function fallback",
          cmp_utils.map({ "missing" }, function()
            return "function fallback"
          end)()
        )
        assert.is_nil(cmp_utils.map({})())
      end
    )

    it(
      "tries actions in order and stops after the first truthy result",
      function()
        local called = {}
        cmp_utils.actions._test_first = function()
          table.insert(called, "first")
        end
        cmp_utils.actions._test_second = function()
          table.insert(called, "second")
          return true
        end
        cmp_utils.actions._test_third = function()
          table.insert(called, "third")
          return true
        end

        local result = cmp_utils.map({
          "missing",
          "_test_first",
          "_test_second",
          "_test_third",
        })()

        cmp_utils.actions._test_first = nil
        cmp_utils.actions._test_second = nil
        cmp_utils.actions._test_third = nil
        assert.is_true(result)
        assert.same({ "first", "second" }, called)
      end
    )
  end)

  describe("snippet_fix", function()
    it("preserves the placeholder number in the output", function()
      local result = cmp_utils.snippet_fix("${1:world}")
      assert.is_true(result:find("%${1:") ~= nil)
    end)

    it("handles a snippet with no placeholders", function()
      local result = cmp_utils.snippet_fix("plain text")
      assert.equals("plain text", result)
    end)
  end)

  describe("snippet_preview", function()
    it("strips $0 tab-stop markers from the output", function()
      -- When lsp._snippet_grammar is unavailable the fallback path is used.
      local result = cmp_utils.snippet_preview("some text$0")
      assert.is_true(result:find("%$0") == nil)
    end)
  end)

  it(
    "repairs an invalid expansion and restores the top-level session",
    function()
      local original_utils = package.loaded.utils
      local original_active = vim.snippet.active
      local original_expand = vim.snippet.expand
      local original_session = vim.snippet._session
      local top_session = {}
      local expansions = {}
      local warning

      package.loaded.utils = {
        warn = function(message)
          warning = message
        end,
        error = function(message)
          error(message)
        end,
      }
      vim.snippet._session = top_session
      vim.snippet.active = function()
        return true
      end
      vim.snippet.expand = function(snippet)
        table.insert(expansions, snippet)
        if #expansions == 1 then
          error("invalid snippet")
        end
        vim.snippet._session = { nested = true }
      end

      cmp_utils.expand("${1:${2:value}}")
      local restored_session = vim.snippet._session

      package.loaded.utils = original_utils
      vim.snippet.active = original_active
      vim.snippet.expand = original_expand
      vim.snippet._session = original_session

      assert.equals(2, #expansions)
      assert.is_truthy(warning:find("able to fix", 1, true))
      assert.equals(top_session, restored_session)
    end
  )

  describe("setup", function()
    local loaded_blink
    local loaded_config
    local loaded_docs
    local loaded_menu
    local loaded_types
    local loaded_presets
    local original_float_sizes
    local original_pumheight
    local setup_opts

    before_each(function()
      loaded_blink = package.loaded["blink.cmp"]
      loaded_config = package.loaded["blink.cmp.config"]
      loaded_docs = package.loaded["blink.cmp.completion.windows.documentation"]
      loaded_menu = package.loaded["blink.cmp.completion.windows.menu"]
      loaded_types = package.loaded["blink.cmp.types"]
      loaded_presets = package.loaded["blink.cmp.keymap.presets"]
      original_float_sizes = require("utils.window").get_completion_float_sizes
      original_pumheight = vim.o.pumheight
      setup_opts = nil

      package.loaded["blink.cmp"] = {
        setup = function(opts)
          setup_opts = opts
        end,
      }

      package.loaded["blink.cmp.types"] = {
        CompletionItemKind = { "Text", Text = 1 },
      }

      package.loaded["blink.cmp.keymap.presets"] = nil
    end)

    after_each(function()
      package.loaded["blink.cmp"] = loaded_blink
      package.loaded["blink.cmp.config"] = loaded_config
      package.loaded["blink.cmp.completion.windows.documentation"] = loaded_docs
      package.loaded["blink.cmp.completion.windows.menu"] = loaded_menu
      package.loaded["blink.cmp.types"] = loaded_types
      package.loaded["blink.cmp.keymap.presets"] = loaded_presets
      require("utils.window").get_completion_float_sizes = original_float_sizes
      vim.o.pumheight = original_pumheight
      pcall(vim.api.nvim_del_augroup_by_name, "OrbitVimBlinkResize")
    end)

    it(
      "registers blink.compat sources and strips the custom compat option",
      function()
        local opts = {
          keymap = { ["<Tab>"] = { "fallback" } },
          sources = {
            compat = { "cmp_git" },
            default = { "lsp" },
            providers = {
              cmp_git = { score_offset = 10 },
            },
          },
        }

        cmp_utils.setup(opts)

        assert.same(opts, setup_opts)
        assert.is_nil(opts.sources.compat)
        assert.same({ "lsp", "cmp_git" }, opts.sources.default)
        assert.equals("cmp_git", opts.sources.providers.cmp_git.name)
        assert.equals(
          "blink.compat.source",
          opts.sources.providers.cmp_git.module
        )
        assert.equals(10, opts.sources.providers.cmp_git.score_offset)
      end
    )

    it("adds a Tab mapping when the config does not define one", function()
      local opts = {
        keymap = { preset = "enter" },
        sources = { default = {}, providers = {} },
      }

      cmp_utils.setup(opts)

      assert.is_true(type(opts.keymap["<Tab>"][1]) == "function")
      assert.equals("fallback", opts.keymap["<Tab>"][2])
    end)

    it(
      "converts custom provider kinds before blink validates providers",
      function()
        local opts = {
          keymap = { ["<Tab>"] = { "fallback" } },
          sources = {
            default = {},
            providers = {
              minuet = {
                kind = "Minuet",
                transform_items = function(_, items)
                  items[1].label = "changed"
                  return items
                end,
              },
            },
          },
        }

        cmp_utils.setup(opts)

        local provider = opts.sources.providers.minuet
        local kinds = package.loaded["blink.cmp.types"].CompletionItemKind
        local items = provider.transform_items({}, { { label = "original" } })

        assert.is_nil(provider.kind)
        assert.equals(2, kinds.Minuet)
        assert.equals("Minuet", kinds[2])
        assert.equals("changed", items[1].label)
        assert.equals(2, items[1].kind)
        assert.equals("Minuet", items[1].kind_name)
      end
    )

    it("keeps configured and live Blink windows sized after resize", function()
      local sizes = {
        completion = { width = 30, height = 7 },
        documentation = { width = 50, height = 12 },
      }
      local window = require("utils.window")
      window.get_completion_float_sizes = function()
        return vim.deepcopy(sizes)
      end

      local draws = 0
      local menu_updates = 0
      local docs_updates = 0
      local menu = {
        win = {
          config = {},
          get_buf = function()
            return 0
          end,
        },
        renderer = {
          draw = function()
            draws = draws + 1
          end,
        },
        context = {},
        items = {},
        update_position = function()
          menu_updates = menu_updates + 1
        end,
      }
      local docs = {
        win = { config = {} },
        update_position = function()
          docs_updates = docs_updates + 1
        end,
      }
      package.loaded["blink.cmp.completion.windows.menu"] = menu
      package.loaded["blink.cmp.completion.windows.documentation"] = docs

      local opts = {
        keymap = { ["<Tab>"] = { "fallback" } },
        sources = { default = {}, providers = {} },
        completion = {
          menu = {},
          documentation = { window = {} },
        },
      }
      cmp_utils.setup(opts)

      assert.equals(7, vim.o.pumheight)
      assert.equals(7, opts.completion.menu.max_height)
      assert.equals(50, opts.completion.documentation.window.max_width)
      assert.equals(12, opts.completion.documentation.window.max_height)

      sizes.completion.height = 9
      sizes.documentation.width = 60
      sizes.documentation.height = 14
      vim.api.nvim_exec_autocmds("VimResized", {})

      assert.equals(9, menu.win.config.max_height)
      assert.equals(60, docs.win.config.max_width)
      assert.equals(14, docs.win.config.max_height)
      assert.equals(2, draws)
      assert.equals(2, menu_updates)
      assert.equals(2, docs_updates)
    end)
  end)
end)
