describe("utils.cmp", function()
  local cmp_utils = require("utils.cmp")

  describe("snippet_replace", function()
    it("replaces a single placeholder via the transform fn", function()
      local result = cmp_utils.snippet_replace("${1:hello}", function(p)
        return p.text:upper()
      end)
      assert.equals("HELLO", result)
    end)

    it("leaves text with no placeholders unchanged", function()
      local result = cmp_utils.snippet_replace(
        "no placeholders here",
        function(p)
          return p.text
        end
      )
      assert.equals("no placeholders here", result)
    end)

    it("replaces multiple placeholders independently", function()
      local result = cmp_utils.snippet_replace(
        "${1:foo} and ${2:bar}",
        function(p)
          return p.text .. "!"
        end
      )
      assert.equals("foo! and bar!", result)
    end)

    it("passes the placeholder number to the function", function()
      local numbers = {}
      cmp_utils.snippet_replace("${3:a} ${7:b}", function(p)
        table.insert(numbers, tonumber(p.n))
        return p.text
      end)
      assert.same({ 3, 7 }, numbers)
    end)

    it("passes the placeholder text to the function", function()
      local texts = {}
      cmp_utils.snippet_replace("${1:alpha} ${2:beta}", function(p)
        table.insert(texts, p.text)
        return p.text
      end)
      assert.same({ "alpha", "beta" }, texts)
    end)

    it("leaves unmatched $ syntax untouched", function()
      local result = cmp_utils.snippet_replace("$0 end", function(p)
        return p.text
      end)
      assert.equals("$0 end", result)
    end)
  end)

  describe("map", function()
    it("returns a callable function", function()
      assert.is_true(type(cmp_utils.map({})) == "function")
    end)

    it("returns a string fallback when no actions match", function()
      local fn = cmp_utils.map({}, "my_fallback")
      assert.equals("my_fallback", fn())
    end)

    it("invokes a function fallback when no actions match", function()
      local fn = cmp_utils.map({}, function()
        return "from_fn"
      end)
      assert.equals("from_fn", fn())
    end)

    it("returns nil when there is no fallback and no actions match", function()
      local fn = cmp_utils.map({})
      assert.is_nil(fn())
    end)

    it("skips unknown action names without error", function()
      local fn = cmp_utils.map({ "action_that_does_not_exist" })
      local ok = pcall(fn)
      assert.is_true(ok)
    end)

    it("returns true when a registered action returns true", function()
      cmp_utils.actions["_test_true_action"] = function()
        return true
      end
      local fn = cmp_utils.map({ "_test_true_action" })
      assert.is_true(fn())
      cmp_utils.actions["_test_true_action"] = nil
    end)

    it("tries the next action when the first returns nil", function()
      cmp_utils.actions["_test_nil_action"] = function()
        return nil
      end
      cmp_utils.actions["_test_true_action2"] = function()
        return true
      end
      local fn = cmp_utils.map({ "_test_nil_action", "_test_true_action2" })
      assert.is_true(fn())
      cmp_utils.actions["_test_nil_action"] = nil
      cmp_utils.actions["_test_true_action2"] = nil
    end)

    it("stops after the first truthy action", function()
      local called = {}
      cmp_utils.actions["_stop_first"] = function()
        table.insert(called, "first")
        return true
      end
      cmp_utils.actions["_stop_second"] = function()
        table.insert(called, "second")
        return true
      end
      local fn = cmp_utils.map({ "_stop_first", "_stop_second" })
      fn()
      assert.same({ "first" }, called)
      cmp_utils.actions["_stop_first"] = nil
      cmp_utils.actions["_stop_second"] = nil
    end)
  end)

  describe("snippet_fix", function()
    it("returns a string", function()
      assert.is_true(type(cmp_utils.snippet_fix("${1:hello}")) == "string")
    end)

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
    it("returns a string", function()
      assert.is_true(type(cmp_utils.snippet_preview("${1:hello}")) == "string")
    end)

    it("strips $0 tab-stop markers from the output", function()
      -- When lsp._snippet_grammar is unavailable the fallback path is used.
      local result = cmp_utils.snippet_preview("some text$0")
      assert.is_true(result:find("%$0") == nil)
    end)

    it("returns non-empty string for a non-trivial snippet", function()
      local result = cmp_utils.snippet_preview("${1:value}")
      assert.is_true(#result > 0)
    end)
  end)

  describe("actions table", function()
    it("exposes snippet_forward action", function()
      assert.is_true(type(cmp_utils.actions.snippet_forward) == "function")
    end)

    it("exposes snippet_stop action", function()
      assert.is_true(type(cmp_utils.actions.snippet_stop) == "function")
    end)
  end)

  describe("setup", function()
    local loaded_blink
    local loaded_types
    local loaded_presets
    local setup_opts

    before_each(function()
      loaded_blink = package.loaded["blink.cmp"]
      loaded_types = package.loaded["blink.cmp.types"]
      loaded_presets = package.loaded["blink.cmp.keymap.presets"]
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
      package.loaded["blink.cmp.types"] = loaded_types
      package.loaded["blink.cmp.keymap.presets"] = loaded_presets
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
              copilot = {
                kind = "Copilot",
                transform_items = function(_, items)
                  items[1].label = "changed"
                  return items
                end,
              },
            },
          },
        }

        cmp_utils.setup(opts)

        local provider = opts.sources.providers.copilot
        local kinds = package.loaded["blink.cmp.types"].CompletionItemKind
        local items = provider.transform_items({}, { { label = "original" } })

        assert.is_nil(provider.kind)
        assert.equals(2, kinds.Copilot)
        assert.equals("Copilot", kinds[2])
        assert.equals("changed", items[1].label)
        assert.equals(2, items[1].kind)
        assert.equals("Copilot", items[1].kind_name)
      end
    )
  end)
end)
