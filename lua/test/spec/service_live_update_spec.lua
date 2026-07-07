describe("service.live_update", function()
  local live_update

  before_each(function()
    package.loaded["service.live_update"] = nil
    live_update = require("service.live_update")
  end)

  after_each(function()
    live_update.stop()
  end)

  it("starts and stops the configured live update augroup", function()
    local ui = {
      win = nil,
      category_idx = 1,
      help_open = false,
      live_augroup = nil,
    }

    live_update.init({
      ui = ui,
      render = function() end,
    })

    live_update.start()
    assert.equals("number", type(ui.live_augroup))

    live_update.stop()
    assert.is_nil(ui.live_augroup)
  end)
end)
