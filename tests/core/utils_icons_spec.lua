describe("utils.icons", function()
  local saved_loaded = {}
  local saved_preload = {}
  local saved_mini_icons
  local module_names = {
    "mini.icons",
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

    local icons = reload_icons()

    assert.equals("M", icons.get_file_icon("init.lua"))
    assert.is_true(setup_called)
    assert.equals(
      "%#MiniIconsBlue#M%*",
      icons.get_file_icon("init.lua", { colored = true })
    )
  end)

  it("returns an empty string when no provider is available", function()
    package.preload["mini.icons"] = function()
      error("mini.icons unavailable")
    end

    local icons = reload_icons()

    assert.equals("", icons.get_file_icon("init.lua"))
  end)
end)
