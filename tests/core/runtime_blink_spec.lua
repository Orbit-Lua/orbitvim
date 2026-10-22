describe("runtime.completion.blink", function()
  local cmp_utils = require("runtime.completion.blink")
  local loaded_blink
  local loaded_config
  local loaded_docs
  local loaded_menu
  local original_float_sizes
  local original_pumheight

  before_each(function()
    loaded_blink = package.loaded["blink.cmp"]
    loaded_config = package.loaded["blink.cmp.config"]
    loaded_docs = package.loaded["blink.cmp.completion.windows.documentation"]
    loaded_menu = package.loaded["blink.cmp.completion.windows.menu"]
    original_float_sizes = require("utils.window").get_completion_float_sizes
    original_pumheight = vim.o.pumheight
    package.loaded["blink.cmp"] = {
      setup = function() end,
    }
  end)

  after_each(function()
    package.loaded["blink.cmp"] = loaded_blink
    package.loaded["blink.cmp.config"] = loaded_config
    package.loaded["blink.cmp.completion.windows.documentation"] = loaded_docs
    package.loaded["blink.cmp.completion.windows.menu"] = loaded_menu
    require("utils.window").get_completion_float_sizes = original_float_sizes
    vim.o.pumheight = original_pumheight
    pcall(vim.api.nvim_del_augroup_by_name, "OrbitVimBlinkResize")
  end)

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
