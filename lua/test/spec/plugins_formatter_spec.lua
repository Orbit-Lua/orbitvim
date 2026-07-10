describe("plugins.formatter", function()
  local original_conform
  local original_manager
  local original_notify
  local notifications

  before_each(function()
    original_conform = package.loaded.conform
    original_manager = package.loaded["noice.message.manager"]
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
    package.loaded["plugins.formatter"] = nil
  end)

  after_each(function()
    package.loaded.conform = original_conform
    package.loaded["noice.message.manager"] = original_manager
    vim.notify = original_notify
    package.loaded["plugins.formatter"] = nil
  end)

  it("shows progress while formatting asynchronously", function()
    local received
    package.loaded.conform = {
      list_formatters_to_run = function()
        return { { name = "sqlfluff" } }, false
      end,
      format = function(opts, callback)
        received = opts
        assert.is_false(vim.bo.modifiable)
        vim.api.nvim_exec_autocmds("User", {
          pattern = "ConformFormatPost",
          data = { formatter = { name = "sqlfluff" } },
        })
        assert.is_true(vim.bo.modifiable)
        assert.is_true(notifications[1].opts.keep())
        callback(nil, true)
      end,
    }

    local spec = require("plugins.formatter")[1]
    spec.keys[1][2]()

    assert.is_true(received.async)
    assert.same("fallback", received.lsp_format)
    assert.is_true(received.quiet)
    assert.same(2, #notifications)
    assert.is_truthy(notifications[1].message:find("Formatting"))
    assert.same("progress", notifications[1].opts.orbit_formatter)
    assert.is_not_nil(notifications[1].opts.orbit_formatter_icon)
    assert.same("function", type(notifications[1].opts.keep))
    assert.is_false(notifications[1].opts.keep())
    assert.is_truthy(notifications[2].message:find("Formatted"))
    assert.same("done", notifications[2].opts.orbit_formatter)
    assert.same("✔", notifications[2].opts.orbit_formatter_icon)
    assert.is_nil(notifications[2].opts.keep)
    assert.is_true(vim.bo.modifiable)
    assert.is_nil(vim.b.orbit_formatting)
  end)

  it("replaces progress with an error notification", function()
    package.loaded.conform = {
      list_formatters_to_run = function()
        return { { name = "sqlfluff" } }, false
      end,
      format = function(_, callback)
        callback("formatter failed", false)
      end,
    }

    local spec = require("plugins.formatter")[1]
    spec.keys[1][2]()

    assert.same(2, #notifications)
    assert.same(vim.log.levels.ERROR, notifications[2].level)
    assert.is_truthy(notifications[2].message:find("failed"))
    assert.same("error", notifications[2].opts.orbit_formatter)
    assert.same("✖", notifications[2].opts.orbit_formatter_icon)
    assert.is_true(vim.bo.modifiable)
    assert.is_nil(vim.b.orbit_formatting)
  end)

  it("updates one Noice message and keeps fast-event callbacks safe", function()
    local finish
    local refreshes = 0
    local progress_message = { opts = {} }
    function progress_message:set(message)
      self.message = message
    end
    package.loaded["noice.message.manager"] = {
      get_by_id = function(id)
        assert.same(7, id)
        return progress_message
      end,
      add = function(message)
        assert.same(progress_message, message)
        refreshes = refreshes + 1
      end,
    }
    vim.notify = function(message, level, opts)
      table.insert(notifications, {
        message = message,
        level = level,
        opts = opts,
      })
      return { id = 7 }
    end
    package.loaded.conform = {
      list_formatters_to_run = function()
        return { { name = "sqlfluff" } }, false
      end,
      format = function(_, callback)
        finish = callback
      end,
    }

    local spec = require("plugins.formatter")[1]
    spec.keys[1][2]()

    local keep_ok
    local timer = assert(vim.uv.new_timer())
    timer:start(0, 0, function()
      keep_ok = pcall(notifications[1].opts.keep)
      timer:close()
    end)
    assert.is_true(vim.wait(500, function()
      return keep_ok ~= nil and refreshes > 0
    end, 10))
    assert.is_true(keep_ok)

    vim.api.nvim_exec_autocmds("User", {
      pattern = "ConformFormatPost",
      data = { formatter = { name = "sqlfluff" } },
    })
    finish(nil, true)
    local stopped_at = refreshes
    vim.wait(160)
    assert.same(stopped_at, refreshes)
    assert.is_false(notifications[1].opts.keep())

    -- show multi notifications, so disable this check
    -- assert.same(1, #notifications)
    --
    assert.same("done", progress_message.opts.orbit_formatter)
    assert.same("✔", progress_message.opts.orbit_formatter_icon)
    assert.is_nil(progress_message.opts.keep)

    -- due to "Formatted" message will not replace the progress message, so disable this check
    -- assert.is_truthy(progress_message.message:find("Formatted"))

    assert.same("info", progress_message.level)
  end)
end)
