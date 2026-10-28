describe("Prisma formatting shortcut", function()
  it(
    "formats unsaved buffer content through a temporary schema without writing the original",
    function()
      local test = require("tests.helpers")
      test.configure_tool()
      assert.equals(
        1,
        vim.fn.executable("node"),
        "Node.js is required for the Prisma adapter test"
      )
      vim.opt.runtimepath:append(test.plugin_path("conform.nvim"))
      local root = test.temp_dir("Prisma project with spaces")
      vim.fn.mkdir(root .. "/.git", "p")
      local source = root .. "/schema.prisma"
      test.write_file(source, "disk contents")
      local cli = root .. "/node_modules/prisma/build/index.js"
      test.write_file(cli, [[
const assert = require('node:assert/strict');
const fs = require('node:fs');
const args = process.argv.slice(2);
assert.equal(args[0], 'format');
assert.equal(args[1], '--schema');
const target = args[2];
]] .. "assert.notEqual(target, " .. vim.json.encode(source) .. ");\n" .. [[
assert.equal(fs.readFileSync(target, 'utf8'), 'unsaved contents\n');
fs.writeFileSync(target, 'formatted unsaved contents\n');
]])
      if not require("utils.os").is_win() then
        local executable = root .. "/node_modules/.bin/prisma"
        test.write_file(
          executable,
          '#!/bin/sh\nexec node "' .. cli .. '" "$@"\n'
        )
        assert(vim.uv.fs_chmod(executable, 493))
      end
      vim.cmd.edit(source)
      local buffer = vim.api.nvim_get_current_buf()
      vim.bo[buffer].filetype = "prisma"
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "unsaved contents" })
      require("conform").setup(require("features.formatter.runtime").options())
      vim.g.mapleader = " "
      local clients = vim.lsp.get_clients
      vim.lsp.get_clients = function()
        return {
          {
            name = "prismals",
            supports_method = function()
              return false
            end,
          },
        }
      end
      require("features.lsp.runtime.keymaps").on_attach(nil, buffer)
      vim.lsp.get_clients = clients
      local mapping = vim.fn.maparg("<leader>fP", "n", false, true)
      assert.is_function(mapping.callback)
      mapping.callback()
      local other = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_set_current_buf(other)
      assert.is_true(vim.wait(10000, function()
        return not vim.b[buffer].orbit_formatting
      end, 10))
      assert.same(
        { "formatted unsaved contents" },
        vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      )
      assert.is_true(vim.bo[buffer].modified)
      assert.same({ "disk contents" }, vim.fn.readfile(source))
      assert.same({ "" }, vim.api.nvim_buf_get_lines(other, 0, -1, false))
    end
  )
end)
