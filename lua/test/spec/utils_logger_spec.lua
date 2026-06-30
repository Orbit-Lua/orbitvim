describe("utils.logger", function()
  local logger

  before_each(function()
    package.loaded["utils.logger"] = nil
    logger = require("utils.logger")
  end)

  describe("write", function()
    it("adds an entry to the named channel", function()
      logger.write("test_ch", "INFO", "src1", "hello")
      assert.equals(1, #logger.get_entries("test_ch"))
    end)

    it("stores all provided fields", function()
      logger.write(
        "test_fields",
        "ERROR",
        "mysrc",
        "test message",
        { kind = "boom" }
      )
      local e = logger.get_entries("test_fields")[1]
      assert.equals("ERROR", e.level)
      assert.equals("mysrc", e.source)
      assert.equals("test message", e.message)
      assert.equals("boom", e.tags.kind)
    end)

    it("stores an ISO-like timestamp", function()
      logger.write("test_ts", "INFO", "s", "m")
      local e = logger.get_entries("test_ts")[1]
      assert.is_not_nil(e.timestamp)
      assert.is_true(e.timestamp:match("%d%d%d%d%-%d%d%-%d%d") ~= nil)
    end)

    it("stores an empty tags table when tags are omitted", function()
      logger.write("test_tags", "INFO", "s", "m")
      local e = logger.get_entries("test_tags")[1]
      assert.same({}, e.tags)
    end)

    it("accumulates multiple entries in order", function()
      logger.write("test_multi", "INFO", "s", "first")
      logger.write("test_multi", "INFO", "s", "second")
      logger.write("test_multi", "INFO", "s", "third")
      local entries = logger.get_entries("test_multi")
      assert.equals(3, #entries)
      assert.equals("first", entries[1].message)
      assert.equals("third", entries[3].message)
    end)
  end)

  describe("get_entries", function()
    it("returns an empty table for an unknown channel", function()
      assert.same({}, logger.get_entries("channel_that_does_not_exist"))
    end)

    it("returns all entries when source is not specified", function()
      logger.write("ge_all", "INFO", "a", "m1")
      logger.write("ge_all", "INFO", "b", "m2")
      assert.equals(2, #logger.get_entries("ge_all"))
    end)

    it("filters by source when source is specified", function()
      logger.write("ge_filter", "INFO", "alpha", "m1")
      logger.write("ge_filter", "INFO", "beta", "m2")
      logger.write("ge_filter", "INFO", "alpha", "m3")
      local entries = logger.get_entries("ge_filter", "alpha")
      assert.equals(2, #entries)
      for _, e in ipairs(entries) do
        assert.equals("alpha", e.source)
      end
    end)

    it("returns an empty table when source filter matches nothing", function()
      logger.write("ge_nomatch", "INFO", "src", "msg")
      assert.same({}, logger.get_entries("ge_nomatch", "other_src"))
    end)

    it("returns a deep copy, not a live reference", function()
      logger.write("ge_copy", "INFO", "s", "original")
      local snapshot = logger.get_entries("ge_copy")
      snapshot[1].message = "tampered"
      local fresh = logger.get_entries("ge_copy")
      assert.equals("original", fresh[1].message)
    end)
  end)

  describe("clear_source", function()
    it("removes only entries belonging to the specified source", function()
      logger.write("cs_test", "INFO", "keep", "m1")
      logger.write("cs_test", "INFO", "remove", "m2")
      logger.write("cs_test", "INFO", "keep", "m3")
      logger.clear_source("cs_test", "remove")
      local remaining = logger.get_entries("cs_test")
      assert.equals(2, #remaining)
      for _, e in ipairs(remaining) do
        assert.equals("keep", e.source)
      end
    end)

    it("does not error on an unknown channel", function()
      local ok = pcall(logger.clear_source, "ghost_channel_xyz", "src")
      assert.is_true(ok)
    end)

    it(
      "leaves the channel empty when all entries share the cleared source",
      function()
        logger.write("cs_all", "INFO", "only_src", "m")
        logger.clear_source("cs_all", "only_src")
        assert.same({}, logger.get_entries("cs_all"))
      end
    )
  end)

  describe("clear_channel", function()
    it("removes all entries for the channel", function()
      logger.write("cc_test", "INFO", "a", "m1")
      logger.write("cc_test", "INFO", "b", "m2")
      logger.clear_channel("cc_test")
      assert.same({}, logger.get_entries("cc_test"))
    end)

    it("does not affect other channels", function()
      logger.write("cc_other", "INFO", "s", "msg")
      logger.write("cc_clear", "INFO", "s", "msg")
      logger.clear_channel("cc_clear")
      assert.equals(1, #logger.get_entries("cc_other"))
    end)
  end)

  describe("get_log_path", function()
    it("returns a non-empty string", function()
      local p = logger.get_log_path()
      assert.is_true(type(p) == "string")
      assert.is_true(#p > 0)
    end)

    it("path ends with the expected filename", function()
      assert.is_true(logger.get_log_path():match("nvim%-config%.log$") ~= nil)
    end)
  end)

  describe("ring buffer cap", function()
    it("never exceeds max_per_channel (200) entries", function()
      for i = 1, 210 do
        logger.write("ring_cap", "INFO", "src", "msg " .. i)
      end
      assert.is_true(#logger.get_entries("ring_cap") <= 200)
    end)

    it("retains the most recent entries when over cap", function()
      for i = 1, 205 do
        logger.write("ring_order", "INFO", "src", "msg " .. i)
      end
      local entries = logger.get_entries("ring_order")
      assert.equals("msg 205", entries[#entries].message)
    end)

    it("drops the oldest entries first", function()
      for i = 1, 205 do
        logger.write("ring_oldest", "INFO", "src", "msg " .. i)
      end
      local entries = logger.get_entries("ring_oldest")
      assert.is_true(entries[1].message ~= "msg 1")
    end)
  end)
end)
