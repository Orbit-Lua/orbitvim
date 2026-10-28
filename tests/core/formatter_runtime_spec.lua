describe("features.formatter.runtime", function()
  local test = require("tests.helpers")
  local original_conform
  local original_notify
  local original_state_path
  local original_state_module
  local original_runtime_module
  local original_buffer_formatting
  local notifications

  before_each(function()
    original_conform = package.loaded.conform
    original_state_path = vim.g.tool_state_path
    original_state_module = package.loaded["hangar.state"]
    original_runtime_module = package.loaded["features.formatter.runtime"]
    original_buffer_formatting = vim.b.orbit_formatting
    vim.g.tool_state_path = require("tests.helpers").temp_dir(
      "formatter-options"
    ) .. "/tools.json"
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
    package.loaded["features.formatter.runtime"] = nil
  end)

  after_each(function()
    package.loaded.conform = original_conform
    vim.g.tool_state_path = original_state_path
    package.loaded["hangar.state"] = original_state_module
    vim.notify = original_notify
    vim.b.orbit_formatting = original_buffer_formatting
    package.loaded["features.formatter.runtime"] = original_runtime_module
    test.cleanup_all()
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

    require("features.formatter.runtime").format()

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

    require("features.formatter.runtime").format()

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

    require("features.formatter.runtime").format()

    assert.same(vim.log.levels.ERROR, notifications[2].level)
    assert.is_nil(vim.b.orbit_formatting)
  end)

  it("rejects overlapping runs for the same buffer", function()
    package.loaded.conform = {
      format = function() end,
    }
    local runtime = require("features.formatter.runtime")

    runtime.format()
    runtime.format()

    assert.same(vim.log.levels.WARN, notifications[2].level)
    assert.is_truthy(notifications[2].message:find("already"))
  end)

  it(
    "resolves buffer zero before asynchronous work and keeps another buffer untouched",
    function()
      local original = vim.api.nvim_get_current_buf()
      local callback
      package.loaded.conform = {
        format = function(opts, done)
          assert.equals(original, opts.bufnr)
          callback = done
        end,
      }
      require("features.formatter.runtime").format(0)
      local other = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_set_current_buf(other)
      callback(nil, true)
      assert.is_nil(vim.b[original].orbit_formatting)
      assert.is_nil(vim.b[other].orbit_formatting)
      assert.same("done", notifications[#notifications].opts.orbit_formatter)
    end
  )

  it(
    "finishes once when a pending buffer is deleted before its backend completes",
    function()
      local buffer = vim.api.nvim_create_buf(true, false)
      local callback
      package.loaded.conform = {
        format = function(_, done)
          callback = done
        end,
      }
      require("features.formatter.runtime").format(buffer)
      vim.api.nvim_buf_delete(buffer, { force = true })
      assert.is_false(notifications[1].opts.keep())
      assert.same("error", notifications[#notifications].opts.orbit_formatter)
      local completed = #notifications
      callback(nil, true)
      assert.equals(completed, #notifications)
    end
  )
end)
