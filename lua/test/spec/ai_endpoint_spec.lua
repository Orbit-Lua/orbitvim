describe("AI completion endpoint", function()
  local endpoint
  local state_path
  local original_minuet

  local function write_state(content)
    local file = assert(io.open(state_path, "w"))
    assert(file:write(content))
    file:close()
  end

  before_each(function()
    state_path = vim.fn.tempname()
    vim.g.minuet_endpoint_state_path = state_path
    package.loaded["ai.endpoint"] = nil
    endpoint = require("ai.endpoint")
    original_minuet = package.loaded.minuet
  end)

  after_each(function()
    os.remove(state_path)
    vim.g.minuet_endpoint_state_path = nil
    package.loaded.minuet = original_minuet
    package.loaded["ai.endpoint"] = nil
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
end)
