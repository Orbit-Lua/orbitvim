describe("utils.progress", function()
  local original_manager
  local original_notify
  local notifications

  before_each(function()
    original_manager = package.loaded["noice.message.manager"]
    original_notify = vim.notify
    notifications = {}
    package.loaded["utils.progress"] = nil
  end)

  after_each(function()
    package.loaded["noice.message.manager"] = original_manager
    vim.notify = original_notify
    package.loaded["utils.progress"] = nil
  end)

  it("updates one Noice message through its full lifecycle", function()
    local refreshes = 0
    local message = { opts = {} }
    function message:set(value)
      self.message = value
    end
    package.loaded["noice.message.manager"] = {
      get_by_id = function(id)
        assert.same(7, id)
        return message
      end,
      add = function(value)
        assert.same(message, value)
        refreshes = refreshes + 1
      end,
    }
    vim.notify = function(value, level, opts)
      table.insert(
        notifications,
        { message = value, level = level, opts = opts }
      )
      return { id = 7 }
    end

    local progress = require("utils.progress").start({
      message = "Working…",
      notify_opts = { state = "progress", icon = "." },
      interval = 10,
      spinner = function()
        return "o"
      end,
      spinner_field = "icon",
    })
    assert.is_true(vim.wait(200, function()
      return refreshes > 0
    end, 10))
    progress:finish({
      message = "Finished",
      level = vim.log.levels.INFO,
      notify_opts = { state = "done", icon = "ok" },
    })

    local stopped_at = refreshes
    vim.wait(40)
    assert.same(stopped_at, refreshes)
    assert.same(1, #notifications)
    assert.same("Finished", message.message)
    assert.same("done", message.opts.state)
    assert.same("ok", message.opts.icon)
    assert.is_nil(message.opts.keep)
  end)

  it("falls back to a completion notification without Noice", function()
    package.loaded["noice.message.manager"] = false
    vim.notify = function(message, level, opts)
      table.insert(
        notifications,
        { message = message, level = level, opts = opts }
      )
      return 1
    end

    local progress = require("utils.progress").start({ message = "Working…" })
    progress:finish({ message = "Finished" })

    assert.same(2, #notifications)
    assert.is_false(notifications[1].opts.keep())
    assert.same("Finished", notifications[2].message)
  end)
end)
