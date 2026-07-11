describe("config.formatter.runtime", function()
  local original_conform
  local original_notify
  local notifications

  before_each(function()
    original_conform = package.loaded.conform
    original_notify = vim.notify
    notifications = {}
    vim.notify = function(message, level, opts)
      table.insert(notifications, {
        message = message,
        level = level,
        opts = opts,
      })
      return 42
    end
    package.loaded["config.formatter.runtime"] = nil
  end)

  after_each(function()
    package.loaded.conform = original_conform
    vim.notify = original_notify
    vim.b.orbit_formatting = nil
    package.loaded["config.formatter.runtime"] = nil
  end)

  it("formats asynchronously without changing buffer modifiability", function()
    local received
    package.loaded.conform = {
      format = function(opts, callback)
        received = opts
        assert.is_true(vim.bo.modifiable)
        assert.is_true(vim.b.orbit_formatting)
        assert.is_true(notifications[1].opts.keep())
        callback(nil, true)
      end,
    }

    require("config.formatter.runtime").format()

    assert.is_true(received.async)
    assert.same(vim.api.nvim_get_current_buf(), received.bufnr)
    assert.is_true(received.quiet)
    assert.same(2, #notifications)
    assert.same("progress", notifications[1].opts.orbit_formatter)
    assert.is_false(notifications[1].opts.keep())
    assert.is_truthy(notifications[2].message:find("Formatted"))
    assert.same("done", notifications[2].opts.orbit_formatter)
    assert.same("✔", notifications[2].opts.orbit_formatter_icon)
    assert.is_true(vim.bo.modifiable)
    assert.is_nil(vim.b.orbit_formatting)
  end)

  it("reports formatter errors and clears runtime state", function()
    package.loaded.conform = {
      format = function(_, callback)
        callback("formatter failed", false)
      end,
    }

    require("config.formatter.runtime").format()

    assert.same(vim.log.levels.ERROR, notifications[2].level)
    assert.is_truthy(notifications[2].message:find("failed"))
    assert.same("error", notifications[2].opts.orbit_formatter)
    assert.same("✖", notifications[2].opts.orbit_formatter_icon)
    assert.is_nil(vim.b.orbit_formatting)
  end)

  it("recovers when Conform raises synchronously", function()
    package.loaded.conform = {
      format = function()
        error("unexpected failure")
      end,
    }

    require("config.formatter.runtime").format()

    assert.same(vim.log.levels.ERROR, notifications[2].level)
    assert.is_nil(vim.b.orbit_formatting)
  end)

  it("rejects overlapping runs for the same buffer", function()
    package.loaded.conform = {
      format = function() end,
    }
    local runtime = require("config.formatter.runtime")

    runtime.format()
    runtime.format()

    assert.same(vim.log.levels.WARN, notifications[2].level)
    assert.is_truthy(notifications[2].message:find("already"))
  end)
end)
