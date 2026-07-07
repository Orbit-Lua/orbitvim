describe("utils.icons", function()
  local saved_loaded = {}
  local saved_preload = {}
  local saved_mini_icons
  local module_names = {
    "mini.icons",
    "nvim-web-devicons",
    "utils.icons",
  }

  local function reload_icons()
    package.loaded["utils.icons"] = nil
    return require("utils.icons")
  end

  before_each(function()
    saved_mini_icons = _G.MiniIcons

    for _, name in ipairs(module_names) do
      saved_loaded[name] = package.loaded[name]
      saved_preload[name] = package.preload[name]
      package.loaded[name] = nil
      package.preload[name] = nil
    end

    _G.MiniIcons = nil
  end)

  after_each(function()
    for _, name in ipairs(module_names) do
      package.loaded[name] = saved_loaded[name]
      package.preload[name] = saved_preload[name]
    end

    _G.MiniIcons = saved_mini_icons
  end)

  it("uses mini.icons by default", function()
    local setup_called = false

    package.preload["mini.icons"] = function()
      return {
        setup = function()
          setup_called = true
          _G.MiniIcons = {}
        end,
        get = function(category, name)
          assert.equals("file", category)
          assert.equals("init.lua", name)
          return "M", "MiniIconsBlue"
        end,
      }
    end

    package.preload["nvim-web-devicons"] = function()
      return {
        get_icon = function()
          error("nvim-web-devicons should not be used")
        end,
      }
    end

    local icons = reload_icons()

    assert.equals("M", icons.get_file_icon("init.lua"))
    assert.is_true(setup_called)
  end)

  it("formats mini.icons highlight groups when colored", function()
    package.preload["mini.icons"] = function()
      return {
        setup = function()
          _G.MiniIcons = {}
        end,
        get = function()
          return "M", "MiniIconsBlue"
        end,
      }
    end

    local icons = reload_icons()

    assert.equals(
      "%#MiniIconsBlue#M%*",
      icons.get_file_icon("init.lua", {
        colored = true,
      })
    )
  end)

  it("falls back to nvim-web-devicons compatibility", function()
    package.preload["mini.icons"] = function()
      error("mini.icons unavailable")
    end

    package.preload["nvim-web-devicons"] = function()
      return {
        get_icon = function(name, ext, opts)
          assert.equals("init.lua", name)
          assert.equals("lua", ext)
          assert.is_true(opts.default)
          return "D", "DevIconLua"
        end,
      }
    end

    local icons = reload_icons()

    assert.equals(
      "%#DevIconLua#D%*",
      icons.get_file_icon("init.lua", {
        colored = true,
      })
    )
  end)

  it("returns an empty string when no provider is available", function()
    package.preload["mini.icons"] = function()
      error("mini.icons unavailable")
    end

    package.preload["nvim-web-devicons"] = function()
      error("nvim-web-devicons unavailable")
    end

    local icons = reload_icons()

    assert.equals("", icons.get_file_icon("init.lua"))
  end)

  it("exposes get_file_icons as a compatibility alias", function()
    local icons = reload_icons()

    assert.equals(icons.get_file_icon, icons.get_file_icons)
  end)
end)
