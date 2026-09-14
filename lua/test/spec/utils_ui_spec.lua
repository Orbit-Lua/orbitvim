describe("utils.ui compatibility facade", function()
  it("delegates behavior to the owning modules", function()
    local ui = require("utils.ui")
    local expected = {
      trunc = require("utils.str").trunc,
      rpad = require("utils.str").rpad,
      fill_line = require("utils.str").fill_line,
      buf_hl = require("utils.hl").buf_hl,
      win_is_floating = require("utils.window").is_floating,
      get_completion_window_size = require("utils.window").get_completion_size,
      get_doc_window_size = require("utils.window").get_doc_size,
      check_toggle_term = require("utils.term").can_toggle,
      harpoon = require("utils.harpoon"),
    }

    for name, implementation in pairs(expected) do
      assert.equals(implementation, ui[name], name .. " must remain compatible")
    end
  end)
end)
