describe("utils.logger", function()
  local logger

  before_each(function()
    package.loaded["utils.logger"] = nil
    logger = require("utils.logger")
  end)

  it("records structured entries in memory and on disk", function()
    logger.write("runtime", "WARN", "sqlfluff", "missing binary", {
      kind = "binary_not_found",
    })
    logger.write("runtime", "INFO", "conform", "ready")

    local entries = logger.get_entries("runtime")
    assert.equals(2, #entries)
    assert.same({ kind = "binary_not_found" }, entries[1].tags)
    assert.same({}, entries[2].tags)
    assert.matches(
      "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d$",
      entries[1].timestamp
    )

    local output = table.concat(vim.fn.readfile(logger.get_log_path()), "\n")
    assert.is_truthy(output:find("[WARN] [sqlfluff] missing binary", 1, true))
  end)

  it("filters entries and returns defensive copies", function()
    logger.write("filter", "INFO", "alpha", "one")
    logger.write("filter", "INFO", "beta", "two")
    logger.write("filter", "INFO", "alpha", "three")

    local filtered = logger.get_entries("filter", "alpha")
    assert.same({ "one", "three" }, {
      filtered[1].message,
      filtered[2].message,
    })

    filtered[1].message = "mutated"
    assert.equals("one", logger.get_entries("filter", "alpha")[1].message)
    assert.same({}, logger.get_entries("missing"))
  end)

  it("clears a source or an entire channel without affecting others", function()
    logger.write("clear", "INFO", "keep", "one")
    logger.write("clear", "INFO", "remove", "two")
    logger.write("other", "INFO", "keep", "three")

    logger.clear_source("clear", "remove")
    assert.equals("one", logger.get_entries("clear")[1].message)
    logger.clear_source("missing", "remove")
    logger.clear_channel("clear")

    assert.same({}, logger.get_entries("clear"))
    assert.equals("three", logger.get_entries("other")[1].message)
  end)

  it("keeps only the 200 most recent entries per channel", function()
    for index = 1, 205 do
      logger.write("ring", "INFO", "source", "message " .. index)
    end

    local entries = logger.get_entries("ring")
    assert.equals(200, #entries)
    assert.equals("message 6", entries[1].message)
    assert.equals("message 205", entries[#entries].message)
  end)
end)
