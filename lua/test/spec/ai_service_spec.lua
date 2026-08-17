describe("AI completion service", function()
  local original_executable
  local original_lazy
  local original_minuet
  local original_notify_once
  local original_system
  local service
  local load_count
  local notifications

  local function wait_for(predicate)
    assert.is_true(vim.wait(1000, predicate), "timed out waiting for callback")
  end

  before_each(function()
    original_executable = vim.fn.executable
    original_lazy = package.loaded.lazy
    original_minuet = package.loaded.minuet
    original_notify_once = vim.notify_once
    original_system = vim.system

    load_count = 0
    notifications = {}
    package.loaded.minuet = nil
    package.loaded.lazy = {
      load = function()
        load_count = load_count + 1
        package.loaded.minuet = {
          config = {
            provider_options = {
              openai_fim_compatible = {},
            },
          },
        }
      end,
    }
    vim.fn.executable = function()
      return 1
    end
    vim.notify_once = function(message, level, opts)
      notifications[#notifications + 1] = {
        message = message,
        level = level,
        opts = opts,
      }
    end

    package.loaded["ai.service"] = nil
    service = require("ai.service")
  end)

  after_each(function()
    vim.fn.executable = original_executable
    vim.system = original_system
    vim.notify_once = original_notify_once
    package.loaded.lazy = original_lazy
    package.loaded.minuet = original_minuet
    package.loaded["ai.service"] = nil
  end)

  it(
    "loads Minuet only after the models endpoint responds successfully",
    function()
      local command
      local system_opts
      local completed
      local persisted
      vim.system = function(args, opts, on_exit)
        command = args
        system_opts = opts
        on_exit({ code = 0, signal = 0, stderr = "" })
        return {}
      end

      service.activate("https://workstation.example.ts.net", {
        before_enable = function(url)
          persisted = url
          return url
        end,
        on_complete = function(ok)
          completed = ok
        end,
      })

      assert.is_false(service.is_ready())
      assert.equals(0, load_count)
      wait_for(function()
        return completed ~= nil
      end)

      assert.same({
        "curl",
        "--silent",
        "--show-error",
        "--fail",
        "--connect-timeout",
        "1",
        "--max-time",
        "3",
        "--header",
        "Host: localhost:11434",
        "https://workstation.example.ts.net/v1/models",
      }, command)
      assert.same({ text = true, timeout = 3500, stdout = false }, system_opts)
      assert.equals(
        "https://workstation.example.ts.net/v1/completions",
        persisted
      )
      assert.is_true(service.is_ready())
      assert.equals(persisted, service.current())
      assert.equals(1, load_count)
      assert.equals(
        persisted,
        package.loaded.minuet.config.provider_options.openai_fim_compatible.end_point
      )
      assert.same({}, notifications)
    end
  )

  it("keeps Minuet disabled and reports the curl failure once", function()
    local completed
    local persisted = false
    local reason
    vim.system = function(_, _, on_exit)
      on_exit({
        code = 7,
        signal = 0,
        stderr = "curl: (7) Failed to connect to ollama.local\nextra detail",
      })
      return {}
    end

    service.activate("ollama.local:1234", {
      before_enable = function()
        persisted = true
        return true
      end,
      on_complete = function(ok, failure)
        completed = ok
        reason = failure
      end,
    })
    wait_for(function()
      return completed ~= nil
    end)

    assert.is_false(completed)
    assert.equals("curl: (7) Failed to connect to ollama.local", reason)
    assert.is_false(persisted)
    assert.is_false(service.is_ready())
    assert.equals(0, load_count)
    assert.equals(1, #notifications)
    assert.matches("Completion disabled", notifications[1].message)
    assert.matches("Failed to connect", notifications[1].message)
    assert.equals(vim.log.levels.WARN, notifications[1].level)
    assert.equals("Minuet", notifications[1].opts.title)
  end)

  it("catches a failure to start curl without loading Minuet", function()
    local completed
    local reason
    vim.system = function()
      error("spawn failed")
    end

    assert.has_no.errors(function()
      service.activate("127.0.0.1:11434", {
        on_complete = function(ok, failure)
          completed = ok
          reason = failure
        end,
      })
    end)
    wait_for(function()
      return completed ~= nil
    end)

    assert.is_false(completed)
    assert.matches("failed to start curl", reason)
    assert.is_false(service.is_ready())
    assert.equals(0, load_count)
  end)
end)
