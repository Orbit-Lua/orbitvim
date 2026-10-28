describe("configured parser installation", function()
  it(
    "passes the canonical parser list through TSInstallAll without Lazy internals",
    function()
      local previous = package.loaded["nvim-treesitter"]
      local received
      package.loaded["nvim-treesitter"] = {
        install = function(names)
          received = names
        end,
      }
      require("features.treesitter.commands").setup()
      local ok, err = pcall(vim.cmd.TSInstallAll)
      package.loaded["nvim-treesitter"] = previous
      vim.api.nvim_del_user_command("TSInstallAll")
      assert.is_true(ok, err)
      local expected = vim.tbl_keys(require("features.hangar.config").parser)
      table.sort(expected)
      assert.same(expected, received)
    end
  )
end)
