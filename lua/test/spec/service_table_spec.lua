describe("service.table", function()
  local service_table = require("service.table")

  it("renders a fixed-width header and rows", function()
    local header, lines = service_table.render({
      width = 30,
      indent = 2,
      columns = {
        { key = "name", label = "Name", width = 10 },
        { key = "status", label = "Status", grow = true },
      },
      rows = {
        { cells = { name = "lua_ls", status = "enabled" } },
      },
    })

    assert.equals(30, vim.fn.strdisplaywidth(header))
    assert.equals(1, #lines)
    assert.equals(30, vim.fn.strdisplaywidth(lines[1]))
    assert.is_true(lines[1]:match("lua_ls") ~= nil)
  end)

  it("copies row entries and records cell byte offsets", function()
    local _, _, line_map = service_table.render({
      width = 40,
      indent = 2,
      columns = {
        { key = "icon", label = "", width = 1 },
        { key = "name", label = "Name", width = 10 },
        { key = "status", label = "Status", grow = true },
      },
      rows = {
        {
          cells = { icon = "x", name = "stylua", status = "ok" },
          icon_cell = "icon",
          entry = {
            name = "stylua",
            kind = "service",
            icon_byte = 0,
            status_byte = 0,
            status_hl = "DiagnosticOk",
          },
        },
      },
    })

    assert.equals("stylua", line_map[1].name)
    assert.equals(2, line_map[1].icon_byte)
    assert.is_true(line_map[1].status_byte > line_map[1].icon_byte)
  end)

  it("adds padding to header and row cells when configured", function()
    local header, lines = service_table.render({
      width = 32,
      indent = 2,
      separator = "|",
      cell_padding = 1,
      columns = {
        { key = "name", label = "Name", width = 10 },
        { key = "status", label = "Status", grow = true },
      },
      rows = {
        { cells = { name = "lua_ls", status = "configured" } },
      },
    })

    assert.is_true(header:match("^   Name") ~= nil)
    assert.is_true(lines[1]:match("^   lua_ls") ~= nil)
    assert.is_true(header:match(" | ", 1, true) ~= nil)
    assert.is_true(lines[1]:match(" | ", 1, true) ~= nil)
  end)

  it("uses padded content offsets for mapped row cells", function()
    local _, _, line_map = service_table.render({
      width = 40,
      indent = 2,
      cell_padding = 1,
      columns = {
        { key = "icon", label = "", width = 3 },
        { key = "status", label = "Status", grow = true },
      },
      rows = {
        {
          cells = { icon = "x", status = "ok" },
          icon_cell = "icon",
          entry = {
            name = "stylua",
            kind = "service",
            icon_byte = 0,
            status_byte = 0,
            status_hl = "DiagnosticOk",
          },
        },
      },
    })

    assert.equals(3, line_map[1].icon_byte)
    assert.is_true(line_map[1].status_byte > line_map[1].icon_byte)
  end)

  it("keeps arrow and icon content inside their cells", function()
    local _, lines, line_map = service_table.render({
      width = 40,
      indent = 0,
      separator = " | ",
      cell_padding = 1,
      columns = {
        { key = "tree", label = "", width = 3 },
        { key = "icon", label = "", width = 3 },
        { key = "name", label = "Name", grow = true },
      },
      rows = {
        {
          cells = { tree = ">", icon = "x", name = "lua_ls" },
          icon_cell = "icon",
          entry = {
            name = "lua_ls",
            kind = "service",
            icon_byte = 0,
            status_byte = 0,
            status_hl = "DiagnosticOk",
          },
        },
      },
    })

    local first_pipe = lines[1]:find(" | ", 1, true)
    local second_pipe = lines[1]:find(" | ", first_pipe + 1, true)

    assert.equals(1, line_map[1].tree_byte)
    assert.equals(2, line_map[1].tree_end_byte)
    assert.equals(7, line_map[1].icon_byte)
    assert.equals(8, line_map[1].icon_end_byte)
    assert.is_true(line_map[1].tree_end_byte < first_pipe - 1)
    assert.is_true(line_map[1].icon_end_byte < second_pipe - 1)
  end)
end)
