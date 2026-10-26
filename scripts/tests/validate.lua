local M = {}

function M.install(path)
  local busted = require("plenary.busted")
  local original = busted.format_results
  busted.format_results = function(results)
    local summary =
      { passed = #results.pass, failed = #results.fail, errors = #results.errs }
    assert(vim.fn.writefile({ vim.json.encode(summary) }, path) == 0)
    original(results)
  end
  busted.pending = function()
    error("skipped tests are not allowed", 0)
  end
  _G.pending = busted.pending
end

function M.check(result)
  assert(result.passed > 0, "test spec executed no tests")
  assert(result.failed == 0 and result.errors == 0, "test spec failed")
end

return M
