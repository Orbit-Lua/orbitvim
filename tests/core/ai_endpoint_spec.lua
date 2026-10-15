describe("AI completion endpoint", function()
  local test = require("tests.helpers")
  local endpoint
  local state_path
  local original_minuet
  local original_endpoint
  local original_rename
  local original_path

  local function write_state(content)
    local file = assert(io.open(state_path, "w"))
    assert(file:write(content))
    file:close()
  end

  before_each(function()
    state_path = test.temp_dir("ai-endpoint") .. "/state.json"
    original_rename = vim.uv.fs_rename
    original_path = vim.g.minuet_endpoint_state_path
    original_endpoint = package.loaded["ai.endpoint"]
    vim.g.minuet_endpoint_state_path = state_path
    package.loaded["ai.endpoint"] = nil
    endpoint = require("ai.endpoint")
    original_minuet = package.loaded.minuet
  end)

  after_each(function()
    vim.uv.fs_rename = original_rename
    vim.g.minuet_endpoint_state_path = original_path
    package.loaded.minuet = original_minuet
    package.loaded["ai.endpoint"] = original_endpoint
    test.cleanup_all()
  end)

  it("normalizes hosts and completion URLs", function()
    assert.equals(
      "http://100.64.0.8:11434/v1/completions",
      endpoint.normalize("100.64.0.8")
    )
    assert.equals(
      "http://ollama.local:1234/v1/completions",
      endpoint.normalize("ollama.local:1234")
    )
    assert.equals(
      "https://workstation.example.ts.net/v1/completions",
      endpoint.normalize("https://workstation.example.ts.net")
    )
    assert.equals(
      "http://127.0.0.1:11434/v1/completions",
      endpoint.normalize("http://127.0.0.1:11434/v1/completions")
    )
    assert.equals(
      "https://workstation.example.ts.net/v1/models",
      endpoint.models_url("https://workstation.example.ts.net")
    )
  end)

  it("rejects unsafe or unsupported endpoint forms", function()
    assert.is_nil(endpoint.normalize("ftp://ollama.local"))
    assert.is_nil(endpoint.normalize("http://user@ollama.local"))
    assert.is_nil(endpoint.normalize("http://ollama.local/api/generate"))
    assert.is_nil(endpoint.normalize("ollama.local:70000"))
    assert.is_nil(endpoint.normalize("ollama local"))
  end)

  it("uses the local endpoint when state is missing or invalid", function()
    assert.equals(endpoint.default_url(), endpoint.current())

    write_state("{ invalid json")
    endpoint._reset()

    assert.equals(endpoint.default_url(), endpoint.current())
    assert.same({ endpoint.default_url() }, endpoint.list())
  end)

  it("filters stale state and preserves a valid current endpoint", function()
    write_state(vim.json.encode({
      current = "tailnet-host:11434",
      endpoints = {
        "tailnet-host:11434",
        "ftp://invalid",
        "tailnet-host:11434",
        42,
      },
    }))

    endpoint._reset()

    assert.equals(
      "http://tailnet-host:11434/v1/completions",
      endpoint.current()
    )
    assert.same({
      endpoint.default_url(),
      "http://tailnet-host:11434/v1/completions",
    }, endpoint.list())
  end)

  it(
    "persists selection and falls back when removing the current endpoint",
    function()
      local remote = assert(endpoint.set("100.64.0.8"))
      assert.equals(remote, endpoint.current())

      endpoint._reset()
      assert.equals(remote, endpoint.current())

      assert.equals(endpoint.default_url(), endpoint.remove(remote))
      assert.equals(endpoint.default_url(), endpoint.current())
      assert.same({ endpoint.default_url() }, endpoint.list())
    end
  )

  it("updates a loaded Minuet configuration", function()
    package.loaded.minuet = {
      config = {
        provider_options = {
          openai_fim_compatible = {
            end_point = endpoint.default_url(),
          },
        },
      },
    }

    local remote = "https://workstation.example.ts.net/v1/completions"
    assert.is_true(endpoint.apply(remote))
    assert.equals(
      remote,
      package.loaded.minuet.config.provider_options.openai_fim_compatible.end_point
    )
  end)

  it("rewrites the Ollama host header only for Tailscale Serve", function()
    local tailscale = {
      end_point = "https://workstation.example.ts.net/v1/completions",
      headers = { Authorization = "Bearer ollama" },
      body = {},
    }
    local local_request = {
      end_point = endpoint.default_url(),
      headers = { Authorization = "Bearer ollama" },
      body = {},
    }

    assert.equals(
      "localhost:11434",
      endpoint.transform_request(tailscale).headers.Host
    )
    assert.is_nil(endpoint.transform_request(local_request).headers.Host)
  end)
  it(
    "retains endpoint selection and disk state when replacement fails",
    function()
      local previous = assert(endpoint.set("prior-host:11434"))
      local before = table.concat(vim.fn.readfile(state_path), "\n")
      vim.uv.fs_rename = function()
        return nil, "replacement refused"
      end
      local selected, err = endpoint.set("next-host:11434")
      assert.is_nil(selected)
      assert.is_truthy(err)
      assert.equals(previous, endpoint.current())
      assert.equals(before, table.concat(vim.fn.readfile(state_path), "\n"))
    end
  )
end)
