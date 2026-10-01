describe("AI statusline", function()
  local bufnr
  local original_minuet
  local original_provider
  local statusline

  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].buftype = ""
    vim.bo[bufnr].modifiable = true

    original_minuet = package.loaded.minuet
    original_provider = package.loaded["minuet.backends.openai_fim_compatible"]

    package.loaded.minuet = nil
    package.loaded["minuet.backends.openai_fim_compatible"] = nil
    package.loaded["ai.statusline"] = nil
    statusline = require("ai.statusline")
  end)

  after_each(function()
    package.loaded.minuet = original_minuet
    package.loaded["minuet.backends.openai_fim_compatible"] = original_provider
    package.loaded["ai.statusline"] = nil

    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end)

  it("reports when Minuet completion is available", function()
    package.loaded.minuet = {
      config = {
        provider = "openai_fim_compatible",
        enable_predicates = {
          function()
            return vim.api.nvim_get_current_buf() == bufnr
          end,
        },
      },
    }
    package.loaded["minuet.backends.openai_fim_compatible"] = {
      is_available = function()
        return true
      end,
    }

    assert.is_true(statusline.is_available(bufnr))
  end)

  it("reports unavailable providers and rejected buffer predicates", function()
    package.loaded.minuet = {
      config = {
        provider = "openai_fim_compatible",
        enable_predicates = {
          function()
            return false
          end,
        },
      },
    }
    package.loaded["minuet.backends.openai_fim_compatible"] = {
      is_available = function()
        return true
      end,
    }

    assert.is_false(statusline.is_available(bufnr))

    package.loaded.minuet.config.enable_predicates = {}
    package.loaded["minuet.backends.openai_fim_compatible"].is_available = function()
      return false
    end

    assert.is_false(statusline.is_available(bufnr))
  end)
end)
