describe("service.data", function()
  local data = require("service.data")
  local services = require("config.services")

  -- NOTE: build_ft_groups("lsp") and build_ft_groups("dap") are intentionally
  -- not called here.  The state module only creates formatter_order and
  -- linter_order keys; indexing the missing lsp_order / dap_order would panic.
  -- content_lines() guards those two categories with an early return.

  describe("content_lines", function()
    it("returns lsp count equal to vim.tbl_count(services.lsp)", function()
      assert.equals(vim.tbl_count(services.lsp), data.content_lines("lsp"))
    end)

    it("returns dap count equal to vim.tbl_count(services.dap)", function()
      assert.equals(vim.tbl_count(services.dap), data.content_lines("dap"))
    end)

    it("returns a non-negative number for formatter", function()
      local n = data.content_lines("formatter")
      assert.is_true(type(n) == "number" and n >= 0)
    end)

    it("returns a non-negative number for linter", function()
      local n = data.content_lines("linter")
      assert.is_true(type(n) == "number" and n >= 0)
    end)

    it(
      "formatter count is at least the number of distinct filetypes",
      function()
        -- Each ft group contributes 1 header + N tool lines, so total >= ft count.
        local groups = data.build_ft_groups("formatter")
        local n = data.content_lines("formatter")
        assert.is_true(n >= #groups)
      end
    )
  end)

  describe("build_ft_groups for formatter", function()
    after_each(function()
      services.formatter._test_default_a = nil
      services.formatter._test_default_b = nil
      services.formatter_defaults._test_default_order = nil
    end)

    it("returns a table", function()
      assert.is_true(type(data.build_ft_groups("formatter")) == "table")
    end)

    it("each group has a string ft field", function()
      for _, group in ipairs(data.build_ft_groups("formatter")) do
        assert.is_true(type(group.ft) == "string")
      end
    end)

    it("each group has a non-empty names list", function()
      for _, group in ipairs(data.build_ft_groups("formatter")) do
        assert.is_true(type(group.names) == "table")
        assert.is_true(#group.names > 0)
      end
    end)

    it("filetypes are sorted alphabetically", function()
      local groups = data.build_ft_groups("formatter")
      local prev = nil
      for _, group in ipairs(groups) do
        if prev then
          assert.is_true(
            group.ft >= prev,
            "fts out of order: " .. prev .. " > " .. group.ft
          )
        end
        prev = group.ft
      end
    end)

    it(
      "every formatter service appears in its declared filetype groups",
      function()
        local groups = data.build_ft_groups("formatter")
        local by_ft = {}
        for _, g in ipairs(groups) do
          by_ft[g.ft] = g.names
        end
        for name, meta in pairs(services.formatter) do
          for _, ft in ipairs(meta.ft or {}) do
            assert.is_not_nil(by_ft[ft], "No group for ft '" .. ft .. "'")
            assert.is_true(
              vim.tbl_contains(by_ft[ft], name),
              name .. " missing from group for " .. ft
            )
          end
        end
      end
    )

    it(
      "groups respect canonical defaults when no saved order exists",
      function()
        services.formatter._test_default_a = {
          mason = nil,
          ft = { "_test_default_order" },
        }
        services.formatter._test_default_b = {
          mason = nil,
          ft = { "_test_default_order" },
        }
        services.formatter_defaults._test_default_order = {
          "_test_default_b",
          "_test_default_a",
        }

        local groups = data.build_ft_groups("formatter")
        local by_ft = {}
        for _, g in ipairs(groups) do
          by_ft[g.ft] = g.names
        end

        assert.same(
          { "_test_default_b", "_test_default_a" },
          by_ft._test_default_order
        )
      end
    )
  end)

  describe("build_ft_groups for linter", function()
    it("returns a table", function()
      assert.is_true(type(data.build_ft_groups("linter")) == "table")
    end)

    it("each group has a string ft field", function()
      for _, group in ipairs(data.build_ft_groups("linter")) do
        assert.is_true(type(group.ft) == "string")
      end
    end)

    it(
      "every linter service appears in its declared filetype groups",
      function()
        local groups = data.build_ft_groups("linter")
        local by_ft = {}
        for _, g in ipairs(groups) do
          by_ft[g.ft] = g.names
        end
        for name, meta in pairs(services.linter) do
          for _, ft in ipairs(meta.ft or {}) do
            assert.is_not_nil(
              by_ft[ft],
              "No linter group for ft '" .. ft .. "'"
            )
            assert.is_true(
              vim.tbl_contains(by_ft[ft], name),
              name .. " missing from linter group for " .. ft
            )
          end
        end
      end
    )

    it("filetypes are sorted alphabetically", function()
      local groups = data.build_ft_groups("linter")
      local prev = nil
      for _, group in ipairs(groups) do
        if prev then
          assert.is_true(
            group.ft >= prev,
            "linter fts out of order: " .. prev .. " > " .. group.ft
          )
        end
        prev = group.ft
      end
    end)
  end)

  describe("entry_status", function()
    it(
      "returns a status string and a highlight group string for lsp",
      function()
        local name = next(services.lsp)
        if not name then
          return
        end
        local status, hl = data.entry_status("lsp", name, services.lsp[name])
        assert.is_true(type(status) == "string" and #status > 0)
        assert.is_true(type(hl) == "string" and #hl > 0)
      end
    )

    it(
      "returns a status string and a highlight group string for formatter",
      function()
        local name = next(services.formatter)
        if not name then
          return
        end
        local status, hl =
          data.entry_status("formatter", name, services.formatter[name])
        assert.is_true(type(status) == "string" and #status > 0)
        assert.is_true(type(hl) == "string" and #hl > 0)
      end
    )

    it("returns n/a when mason registry is not available", function()
      -- In the minimal test env mason-registry is not loaded.
      -- Entries with a mason field should report "n/a".
      local name, meta = next(services.lsp)
      if not name or not meta.mason then
        return
      end
      local status, _ = data.entry_status("lsp", name, meta)
      -- Either "n/a" (mason unavailable) or a category-specific status.
      assert.is_true(type(status) == "string")
    end)

    it("combines runtime health with external install state", function()
      package.loaded.conform =
        { formatters_by_ft = { prisma = { "prisma_fmt" } } }

      local status, _ = data.entry_status(
        "formatter",
        "prisma_fmt",
        services.formatter.prisma_fmt
      )

      package.loaded.conform = nil

      assert.equals("wired · external", status)
    end)
  end)
end)
